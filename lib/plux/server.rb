module Plux

  class Server
    attr_reader :name, :pid

    Active = {}
    at_exit{ Active.values.each(&:close) }

    def initialize(name)
      @name = name
    end

    def boot(block)
      Plux.lock_pid_file(name) do |file|
        start_server_if_not_pid(file, block)
      end
      self
    end

    def close
      Process.kill('TERM', pid) rescue Errno::ESRCH
    end

    def connect
      Client.new(name)
    end

    private

    def start_server_if_not_pid(file, block)
      @pid = file.read.to_i
      return unless pid == 0

      child, parent = IO.pipe

      @pid = fork do
        at_exit{ delete_server }
        file.close
        child.close
        UNIXServer.open(Plux.server_file(name)) do |serv|
          parent.close
          worker = Class.new(&block).new
          loop do
            socket = serv.accept
            Worker.new(socket, worker)
          end
        end
      end

      parent.close
      child.read
      child.close

      file.rewind
      file.write(pid)
      Process.detach(pid)
      Active[name] = self
    end

    def delete_server
      [:server_file, :pid_file].each do |file|
        File.delete(Plux.send(file, name))
      end
    end

    class Worker
      def initialize(socket, worker)
        par = Parser.new
        t = Thread.new do
          loop do
            begin
              stream = socket.read_nonblock(Parser::STREAM_MAX_LEN)
            rescue IO::WaitReadable
              IO.select([socket])
              retry
            end

            msgs = par.decode(stream)
            last_msg = msgs.pop

            msgs.each{ |msg| worker.work(msg) }
            break if last_msg == Parser::LAST_MSG
            worker.work(last_msg)
          end
          socket.close
        end
      end
    end

  end

end

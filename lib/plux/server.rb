module Plux

  class Server
    attr_reader :name, :pid

    Active = {}
    at_exit{ Active.values.each(&:close) }

    def initialize(name, block)
      @name = name

      Plux.lock_pid_file(name) do |file|
        start_server_if_not_pid(file, block)
      end
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
        t = Thread.new do
          client = socket.recv_io
          socket.close
          while line = client.gets
            worker.work(line)
          end
          pp "#{t.object_id} end"
        end
      end
    end

  end

end

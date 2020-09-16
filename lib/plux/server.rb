require "nio"

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
          nio = NIO::Selector.new
          newly_accepted = Queue.new
          closed = []

          Thread.new do
            loop do
              closed.size.times do
                 nio.deregister(closed.pop)
              end
              newly_accepted.size.times do
                socket = newly_accepted.pop
                mon = nio.register(socket, :r)
                mon.value = Worker.new(socket, worker)
              end
              nio.select do |m|
                next if m.value.process
                closed << m.io
              end
            end
          end

          loop do
            newly_accepted << serv.accept
            nio.wakeup
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
        @parser = Parser.new
        @socket = socket
        @worker = worker
      end

      def process
        10.times do
          stream = @socket.read_nonblock(Parser::STREAM_MAX_LEN, exception: false)
          return true if stream == :wait_readable

          msgs = @parser.decode(stream)
          last_msg = msgs.pop

          msgs.each{ |msg| @worker.work(msg) }
          if last_msg == Parser::LAST_MSG
            @socket.close
            return false
          end
          @worker.work(last_msg)
        end
        true
      end
    end

  end

end

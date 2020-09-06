module Plux

  class Server
    attr_reader :name, :pid

    def initialize(name)
      @name = name

      File.open(Plux.pid_file(name), File::RDWR|File::CREAT, 0644) do |file|
        start_server_if_not_pid(file)
      end
    end

    def start_server_if_not_pid(file)
      file.flock(File::LOCK_EX)
      @pid = file.read.to_i
      return unless pid == 0

      child, parent = IO.pipe

      @pid = fork do
        at_exit{ delete_server }
        child.close
        UNIXServer.open(Plux.server_file(name)) do |serv|
          parent.close
          loop do
            socket = serv.accept
            Worker.new(socket)
          end
        end
      end

      parent.close
      child.read
      child.close

      file.rewind
      file.write(pid)
      Process.detach(pid)
    ensure
      file.flock(File::LOCK_UN)
    end

    def close
      Process.kill('TERM', pid) rescue Errno::ESRCH
    end

    def delete_server
      [:server_file, :pid_file].each do |file|
        File.delete(Plux.send(file, name))
      end
    end

    class Worker
      def initialize(socket)
        t = Thread.new do
          client = socket.recv_io
          socket.close
          while line = client.gets
            pp line
          end
          pp "#{t.object_id} end"
        end
      end
    end

  end

end

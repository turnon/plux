require "nio"
require "plux/reactors"

module Plux

  class Server
    attr_reader :name, :pid

    Active = {}
    at_exit{ Active.values.each(&:close) }

    def initialize(name, thread: )
      @name = name
      @thread = thread
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
          reactor = Reactors::Reactor.new(@thread, worker)
          loop{ reactor.register(serv.accept) }
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
  end

end

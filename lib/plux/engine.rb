module Plux
  class Engine

    def initialize(name, thread: 1)
      @server = Server.new(name, thread: thread).boot(self)
    end

    def connect
      @server.connect
    end

    def prepare
    end

    def process(msg)
    end
  end
end

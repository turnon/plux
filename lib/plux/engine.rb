module Plux
  class Engine

    attr_reader :name

    def initialize(name, thread: 1)
      @name = name
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

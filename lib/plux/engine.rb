module Plux
  class Engine

    def initialize(name, thread: 1)
      engine = self

      @server = ::Plux.worker(name, thread: thread) do
        instance_variable_set(:@engine, engine)

        def initialize
          @engine = self.class.instance_variable_get(:@engine)
          @engine.prepare
        end

        def work(msg)
          @engine.process(msg)
        end
      end
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

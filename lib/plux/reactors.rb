module Plux
  class Reactors
    def initialize(count, worker)
      @lock = Mutex.new
      @reactor_loops = count.times.each_with_object({}) do |r, hash|
        hash[Reactor.new(worker, self)] = 0
      end
    end

    def register(socket)
      @lock.synchronize do
        reactor = @reactor_loops.sort_by{ |_, v| v }.first.first
        reactor.register(socket)
      end
    end

    def timer(reactor, duration)
      @lock.synchronize{ @reactor_loops[reactor] += duration }
    end

    class Reactor
      def initialize(worker, reactors)
        @worker = worker
        @reactors = reactors

        @nio = NIO::Selector.new
        @newly_accepted = Queue.new
        @closed = []

        run
      end

      def register(socket)
        @newly_accepted << socket
        @nio.wakeup
      end

      private

      def run
        Thread.new do
          loop do
            @closed.size.times{ @nio.deregister(@closed.pop) }

            @newly_accepted.size.times do
              socket = @newly_accepted.pop
              mon = @nio.register(socket, :r)
              mon.value = Worker.new(socket, @worker)
            end

            start = Time.now.to_i

            next unless @nio.select do |m|
              next if m.value.process
              @closed << m.io
            end

            @reactors.timer(self, Time.now.to_i - start)
          end
        end
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

module Plux
  class Reactors
    def initialize(count, worker)
      @lock = Mutex.new
      @free_reactors = count.times.map{ Reactor.new(worker, self) }
      @reactor_loops = @free_reactors.each_with_object({}){ |r, hash| hash[r] = 0 }
    end

    def register(socket)
      @lock.synchronize do
        reactor = @free_reactors.shift || @reactor_loops.sort_by{ |_, v| v }.last.first
        reactor.register(socket)
      end
    end

    def add_loop(reactor)
      @lock.synchronize{ @reactor_loops[reactor] += 1 }
    end

    def free(reactor)
      @lock.synchronize do
        next if @free_reactors.detect{ |r| r == reactor }
        @free_reactors.push(reactor)
      end
    end

    class Reactor
      def initialize(worker, reactors)
        @worker = worker
        @reactors = reactors

        @nio = NIO::Selector.new
        @newly_accepted = Queue.new
        @closed = []

        @accepted_count = 0
        @closed_count = 0
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
            @closed_count += @closed.size.times{ @nio.deregister(@closed.pop) }
            @reactors.free(self) if @closed_count > 0 && @closed_count == @accepted_count

            @accepted_count += @newly_accepted.size.times do
              socket = @newly_accepted.pop
              mon = @nio.register(socket, :r)
              mon.value = Worker.new(socket, @worker)
            end

            @reactors.add_loop(self) if @nio.select do |m|
              next if m.value.process
              @closed << m.io
            end
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

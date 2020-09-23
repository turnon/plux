module Plux
  class Reactor
    def initialize(count, worker)
      @worker = worker
      @msg_q = Queue.new
      @count = count

      @nio = NIO::Selector.new
      @newly_accepted = Queue.new
      @closed = []

      receive
      process
    end

    def register(socket)
      @newly_accepted << socket
      @nio.wakeup
    end

    private

    def receive
      Thread.new do
        loop do
          @closed.size.times{ @nio.deregister(@closed.pop) }

          @newly_accepted.size.times do
            socket = @newly_accepted.pop
            mon = @nio.register(socket, :r)
            mon.value = Worker.new(socket, @msg_q)
          end

          @nio.select do |m|
            next if m.value.process
            @closed << m.io
          end
        end
      end
    end

    def process
      @count.times.each do
        Thread.new do
          loop{ @worker.process(@msg_q.deq) }
        end
      end
    end

    class Worker
      def initialize(socket, q)
        @parser = Parser.new
        @socket = socket
        @q = q
      end

      def process
        stream = @socket.read_nonblock(Parser::STREAM_MAX_LEN, exception: false)
        return true if stream == :wait_readable

        msgs = @parser.decode(stream)
        last_msg = msgs.pop

        msgs.each{ |msg| @q << msg }
        if last_msg == Parser::LAST_MSG
          @socket.close
          return false
        end
        @q << last_msg

        true
      end
    end

  end
end

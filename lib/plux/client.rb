module Plux
  class Client
    attr_reader :server_name

    def initialize(server_name)
      @server_name = server_name
      UNIXSocket.open(Plux.server_file(server_name)) do |c|
        reader, @writer = IO.pipe
        c.send_io(reader)
        reader.close
      end
    end

    def puts(arg)
      @writer.puts(arg)
    end

    def close
      @writer.close
    end
  end
end

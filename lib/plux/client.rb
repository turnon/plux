module Plux
  class Client
    attr_reader :server_name

    def initialize(server_name)
      @server_name = server_name
      @writer = UNIXSocket.open(Plux.server_file(server_name))
    end

    def puts(msg)
      Parser.encode(msg).each do |sub_msg|
        @writer.write(sub_msg)
      end
    end

    def close
      @writer.close
    end
  end
end

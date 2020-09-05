require "plux/version"
require "plux/server"
require "plux/client"

module Plux

  class << self
    def dir
      File.join(Dir.home, '.plux')
    end

    def pid_file(server_name)
      File.join(dir, "#{server_name}.pid")
    end

    def server_file(server_name)
      File.join(dir, "#{server_name}.so")
    end
  end

  FileUtils.mkdir_p(self.dir)
end

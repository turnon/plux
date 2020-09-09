require "fileutils"
require "socket"
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

    def lock_pid_file(name)
      File.open(pid_file(name), File::RDWR|File::CREAT, 0644) do |file|
        begin
          file.flock(File::LOCK_EX)
          yield file
        ensure
          file.flock(File::LOCK_UN)
        end
      end
    end

    def server_file(server_name)
      File.join(dir, "#{server_name}.so")
    end

    def worker(name, &block)
      Server.new(name).boot(block)
    end
  end

  FileUtils.mkdir_p(self.dir)
end

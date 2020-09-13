module Plux
  class Parser

    SYSTEM = 36
    SEPERATOR = '.'.freeze
    STREAM_MAX_LEN = 4096

    def initialize
      @broken = ''
    end

    def decode(stream)
      stream = @broken.concat(stream)
      result = []

      start = 0
      pending = stream.length

      until start >= pending
        sep_idx = stream.index(SEPERATOR, start)

        unless sep_idx
          len_str = stream[start, pending]
          @broken.clear
          @broken.concat(len_str)
          return result
        end

        len_str = stream[start, sep_idx - start]
        est_len = len_str.to_i(SYSTEM)
        start = sep_idx + 1
        msg = stream[start, est_len]
        act_len = msg.length

        if act_len < est_len
          @broken.clear
          @broken.concat(len_str)
          @broken.concat(SEPERATOR)
          @broken.concat(msg)
          return result
        end

        result << msg
        start += act_len
      end

      @broken.clear
      result
    end

    def self.encode(msg)
      len = msg.length.to_s(SYSTEM)

      msg = "#{len}#{SEPERATOR}#{msg}"
      len = msg.length

      return [msg] if len < STREAM_MAX_LEN

      div, mod = len.divmod(STREAM_MAX_LEN)
      (mod > 0 ? (div + 1) : div).times.map do |start|
        msg[start * STREAM_MAX_LEN, STREAM_MAX_LEN]
      end
    end

  end
end

module Plux
  class Parser

    SYSTEM = 36
    SEPERATOR = '.'.freeze

    def initialize
      @broken = ''
    end

    def parse(stream)
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

  end
end

module Plux
  class Parser

    SYSTEM = 36
    SEPERATOR = '.'.freeze

    def initialize
      @break_word = nil
    end

    def parse(stream)
      if @break_word
        continue_read(stream)
      else
        auto_read(stream, 0, [])
      end
    end

    def continue_read(stream)
      result = []
      msg = stream[0, @remain]
      act_len = msg.length
      @break_word.concat(msg)

      if act_len == @remain
        result << @break_word
        @break_word = nil
        return auto_read(stream, act_len, result)
      end

      @remain -= act_len
      result
    end

    def auto_read(stream, start, result)
      pending = stream.length - start

      until start >= pending
        sep_idx = stream.index(SEPERATOR, start)
        est_len = stream[start, sep_idx - start].to_i(SYSTEM)

        start = sep_idx + 1
        msg = stream[start, est_len]

        act_len = msg.length
        start += act_len

        if act_len == est_len
          result << msg
        else
          @break_word = msg
          @remain = est_len - act_len
        end
      end

      result
    end

  end
end

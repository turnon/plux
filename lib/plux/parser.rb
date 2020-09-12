module Plux
  class Parser

    LENGTH_LEN = 3

    def initialize
      @break_word= nil
    end

    def parse(stream)
      result = []

      if @break_word
        msg = stream[0, @remain]
        result << (@break_word + msg)
        @break_word = nil
        start = @remain
      else
        start = 0
      end

      auto_read(stream, start, result)
    end

    def auto_read(stream, start, result)
      pending = stream.length - start
      read = 0

      until read >= pending
        est_len = stream[start, LENGTH_LEN].to_i
        msg = stream[start + LENGTH_LEN, est_len]

        act_len = msg.length
        start = read = (read + LENGTH_LEN + act_len)

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

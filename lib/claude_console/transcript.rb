# frozen_string_literal: true

require "delegate"

module ClaudeConsole
  class Transcript < SimpleDelegator
    MAX_SIZE = 20_000 # ~20KB cap

    def initialize(io)
      super(io)
      @buffer = String.new
      @capturing = true
      @mutex = Mutex.new
    end

    def write(*args)
      result = __getobj__.write(*args)
      @mutex.synchronize do
        if @capturing
          args.each { |s| @buffer << s.to_s }
          trim_buffer if @buffer.bytesize > MAX_SIZE
        end
      end
      result
    end

    def flush_transcript
      @mutex.synchronize do
        content = @buffer.dup
        @buffer.clear
        content
      end
    end

    def pause
      @capturing = false
    end

    def resume
      @capturing = true
    end

    private

    def trim_buffer
      excess = @buffer.bytesize - MAX_SIZE
      @buffer.replace(@buffer.byteslice(excess..).scrub)
    end
  end
end

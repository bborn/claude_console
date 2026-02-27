require "test_helper"
require "stringio"

class TranscriptTest < Minitest::Test
  def setup
    @io = StringIO.new
    @transcript = ClaudeConsole::Transcript.new(@io)
  end

  def test_write_delegates_to_underlying_io
    @transcript.write("hello")
    assert_equal "hello", @io.string
  end

  def test_write_captures_to_buffer
    @transcript.write("hello ")
    @transcript.write("world\n")
    assert_equal "hello world\n", @transcript.flush_transcript
  end

  def test_flush_clears_buffer
    @transcript.write("data")
    @transcript.flush_transcript
    assert_equal "", @transcript.flush_transcript
  end

  def test_pause_stops_capturing
    @transcript.write("before ")
    @transcript.pause
    @transcript.write("hidden ")
    assert_equal "before ", @transcript.flush_transcript
  end

  def test_resume_restarts_capturing
    @transcript.pause
    @transcript.write("hidden ")
    @transcript.resume
    @transcript.write("visible")
    assert_equal "visible", @transcript.flush_transcript
  end

  def test_pause_still_delegates_writes
    @transcript.pause
    @transcript.write("still visible in IO")
    assert_equal "still visible in IO", @io.string
  end

  def test_trim_buffer_enforces_size_cap
    @transcript.write("x" * 25_000)
    result = @transcript.flush_transcript
    assert_operator result.bytesize, :<=, ClaudeConsole::Transcript::MAX_SIZE
  end

  def test_trim_buffer_keeps_tail
    @transcript.write("A" * 25_000)
    @transcript.write("TAIL")
    result = @transcript.flush_transcript
    assert result.end_with?("TAIL"), "Expected buffer to keep the tail"
  end

  def test_scrub_handles_broken_multibyte_at_trim_boundary
    # Fill buffer to just under the cap, then add multi-byte chars that
    # will force a trim mid-character
    padding = "a" * (ClaudeConsole::Transcript::MAX_SIZE - 5)
    multibyte = "\u{1F600}" * 5 # each emoji is 4 bytes
    @transcript.write(padding + multibyte)
    result = @transcript.flush_transcript
    assert result.valid_encoding?, "Expected valid UTF-8 after trim"
  end
end

class InstallTranscriptTest < Minitest::Test
  def setup
    @original_stdout = $stdout
    @original_transcript = ClaudeConsole.transcript
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  def teardown
    $stdout = @original_stdout
    ClaudeConsole.instance_variable_set(:@transcript, @original_transcript)
  end

  def test_install_wraps_stdout
    ClaudeConsole.install_transcript!
    assert_instance_of ClaudeConsole::Transcript, $stdout
    assert_instance_of ClaudeConsole::Transcript, ClaudeConsole.transcript
  end

  def test_install_is_idempotent
    ClaudeConsole.install_transcript!
    first = ClaudeConsole.transcript
    ClaudeConsole.install_transcript!
    assert_same first, ClaudeConsole.transcript
  end
end

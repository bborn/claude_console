require "test_helper"
require "irb"
require "irb/command"
require "claude_console/command"

class CommandLogicTest < Minitest::Test
  # Test CommandLogic via the IRB Command class
  def setup
    ClaudeConsole.reset_session!
    @command = ClaudeConsole::Command.new(nil)
  end

  # -- parse_response --

  def test_parse_response_extracts_result
    json = '{"result": "Hello from Claude", "session_id": "sess-1"}'
    result = @command.send(:parse_response, json)
    assert_equal "Hello from Claude", result
  end

  def test_parse_response_stores_session_id
    json = '{"result": "ok", "session_id": "sess-42"}'
    @command.send(:parse_response, json)
    assert_equal "sess-42", ClaudeConsole.session_id
  end

  def test_parse_response_without_session_id
    json = '{"result": "ok"}'
    @command.send(:parse_response, json)
    assert_nil ClaudeConsole.session_id
  end

  def test_parse_response_returns_nil_on_invalid_json
    result = @command.send(:parse_response, "not json at all")
    assert_nil result
  end

  def test_parse_response_coerces_nil_result_to_string
    json = '{"session_id": "s1"}'
    result = @command.send(:parse_response, json)
    assert_equal "", result
  end

  # -- process_response --

  def test_process_response_prints_plain_text
    out, = capture_io do
      @command.send(:process_response, "Hello world", binding)
    end
    assert_includes out, "Hello world"
  end

  def test_process_response_skips_empty_text
    out, = capture_io do
      @command.send(:process_response, "  \n  ", binding)
    end
    assert_equal "", out
  end

  def test_process_response_evals_ruby_code_block
    response = "Here's the result:\n```ruby\n1 + 1\n```"
    out, = capture_io do
      @command.send(:process_response, response, binding)
    end
    assert_includes out, ">> Running:"
    assert_includes out, "1 + 1"
    assert_includes out, "=> 2"
  end

  def test_process_response_handles_eval_error
    response = "```ruby\nraise 'boom'\n```"
    _out, err = capture_io do
      @command.send(:process_response, response, binding)
    end
    assert_includes err, "RuntimeError"
    assert_includes err, "boom"
  end

  def test_process_response_handles_multiple_blocks
    response = "First:\n```ruby\n:a\n```\nSecond:\n```ruby\n:b\n```"
    out, = capture_io do
      @command.send(:process_response, response, binding)
    end
    assert_includes out, "=> :a"
    assert_includes out, "=> :b"
  end

  def test_process_response_suppresses_nil_result
    response = "```ruby\nnil\n```"
    out, = capture_io do
      @command.send(:process_response, response, binding)
    end
    refute_includes out, "=> nil"
  end

  def test_process_response_variables_persist_across_blocks
    response = "```ruby\n__test_var = 42\n```\n```ruby\n__test_var * 2\n```"
    out, = capture_io do
      @command.send(:process_response, response, binding)
    end
    assert_includes out, "=> 84"
  end

  # -- build_context --

  def test_build_context_uses_transcript_when_available
    transcript = ClaudeConsole::Transcript.new(StringIO.new)
    transcript.write(">> User.count\n=> 42\n")
    ClaudeConsole.instance_variable_set(:@transcript, transcript)

    result = @command.send(:build_context)
    assert_includes result, "Console transcript"
    assert_includes result, "User.count"
  ensure
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  def test_build_context_returns_empty_when_no_transcript_or_history
    ClaudeConsole.instance_variable_set(:@transcript, nil)
    result = @command.send(:build_context)
    assert_equal "", result
  end

  def test_build_context_flushes_transcript
    transcript = ClaudeConsole::Transcript.new(StringIO.new)
    transcript.write("data")
    ClaudeConsole.instance_variable_set(:@transcript, transcript)

    @command.send(:build_context)
    # Second call should return empty since buffer was flushed
    result = @command.send(:build_context)
    assert_equal "", result
  ensure
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  # -- run_claude --

  def test_run_claude_rejects_empty_prompt
    out, = capture_io do
      @command.send(:run_claude, "", binding)
    end
    assert_includes out, "Usage: claude"
  end

  def test_run_claude_rescues_missing_cli
    original = ClaudeConsole.cli_path
    ClaudeConsole.cli_path = "/nonexistent/path/to/claude"

    _out, err = capture_io do
      @command.send(:run_claude, "hello", binding)
    end
    assert_includes err, "Claude CLI not found"
  ensure
    ClaudeConsole.cli_path = original
  end

  # -- HELP_TEXT constant --

  def test_help_text_constant_exists
    assert_includes ClaudeConsole::CommandLogic::HELP_TEXT, "Usage: claude"
  end
end

require "pry"
require "claude_console/pry_command"

class PryCommandTest < Minitest::Test
  def setup
    ClaudeConsole.reset_session!
    @command = ClaudeConsole::PryCommand.new
  end

  def test_build_context_uses_transcript_when_available
    transcript = ClaudeConsole::Transcript.new(StringIO.new)
    transcript.write(">> Post.last\n=> #<Post id: 1>\n")
    ClaudeConsole.instance_variable_set(:@transcript, transcript)

    result = @command.send(:build_context)
    assert_includes result, "Console transcript"
    assert_includes result, "Post.last"
  ensure
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  def test_build_context_falls_back_to_pry_history
    ClaudeConsole.instance_variable_set(:@transcript, nil)

    # Pry.history is available since we required pry
    result = @command.send(:history_context)
    # Returns empty string if no history items (fresh Pry instance)
    assert_kind_of String, result
  ensure
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  def test_build_context_returns_empty_when_no_transcript_or_history
    ClaudeConsole.instance_variable_set(:@transcript, nil)
    result = @command.send(:build_context)
    assert_equal "", result
  ensure
    ClaudeConsole.instance_variable_set(:@transcript, nil)
  end

  def test_parse_response_works_via_command_logic
    json = '{"result": "pry result", "session_id": "pry-sess"}'
    result = @command.send(:parse_response, json)
    assert_equal "pry result", result
    assert_equal "pry-sess", ClaudeConsole.session_id
  end
end

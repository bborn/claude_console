require "test_helper"

class ClaudeConsoleTest < Minitest::Test
  def setup
    ClaudeConsole.reset_session!
  end

  def test_version
    assert ClaudeConsole::VERSION
  end

  def test_default_cli_path
    assert_equal "claude", ClaudeConsole.cli_path
  end

  def test_custom_cli_path
    original = ClaudeConsole.cli_path
    ClaudeConsole.cli_path = "/usr/local/bin/claude"
    assert_equal "/usr/local/bin/claude", ClaudeConsole.cli_path
  ensure
    ClaudeConsole.cli_path = original
  end

  def test_default_system_prompt
    cmd = ClaudeConsole.command
    idx = cmd.index("--system-prompt")
    assert idx, "command should include --system-prompt"
    assert_includes cmd[idx + 1], "senior Rails developer"
  end

  def test_custom_system_prompt
    original = ClaudeConsole.system_prompt
    ClaudeConsole.system_prompt = "You are a test bot"
    cmd = ClaudeConsole.command
    idx = cmd.index("--system-prompt")
    assert_equal "You are a test bot", cmd[idx + 1]
  ensure
    ClaudeConsole.system_prompt = original
  end

  def test_clean_env_clears_api_keys
    env = ClaudeConsole.clean_env
    assert_nil env["ANTHROPIC_API_KEY"]
    assert_nil env["CLAUDE_CONFIG_DIR"]
  end

  def test_clean_env_clears_custom_vars
    original = ClaudeConsole.clear_env_vars
    ClaudeConsole.clear_env_vars = ["MY_KEY"]
    env = ClaudeConsole.clean_env
    assert_nil env["MY_KEY"]
  ensure
    ClaudeConsole.clear_env_vars = original
  end

  def test_command_uses_json_output
    cmd = ClaudeConsole.command
    idx = cmd.index("--output-format")
    assert idx
    assert_equal "json", cmd[idx + 1]
  end

  def test_command_without_session_uses_system_prompt
    cmd = ClaudeConsole.command
    assert_includes cmd, "--system-prompt"
    refute_includes cmd, "--resume"
  end

  def test_command_with_session_uses_resume
    ClaudeConsole.session_id = "test-session-123"
    cmd = ClaudeConsole.command
    assert_includes cmd, "--resume"
    assert_includes cmd, "test-session-123"
    refute_includes cmd, "--system-prompt"
  ensure
    ClaudeConsole.reset_session!
  end

  def test_reset_session
    ClaudeConsole.session_id = "abc"
    ClaudeConsole.reset_session!
    assert_nil ClaudeConsole.session_id
  end
end

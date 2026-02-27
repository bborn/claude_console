require "test_helper"

class ClaudeConsoleTest < Minitest::Test
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
    assert_includes ClaudeConsole.command, ClaudeConsole::SYSTEM_PROMPT
  end

  def test_custom_system_prompt
    original = ClaudeConsole.system_prompt
    ClaudeConsole.system_prompt = "You are a test bot"
    assert_includes ClaudeConsole.command, "You are a test bot"
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

  def test_command_structure
    cmd = ClaudeConsole.command
    assert_equal "claude", cmd[0]
    assert_equal "-p", cmd[1]
    assert_equal "--system-prompt", cmd[2]
    assert_equal "--output-format", cmd[4]
    assert_equal "text", cmd[5]
  end
end

# frozen_string_literal: true

require_relative "claude_console/version"

require_relative "claude_console/railtie" if defined?(Rails)

module ClaudeConsole
  SYSTEM_PROMPT = <<~PROMPT
    You are a senior Rails developer pair-programming inside a live Rails console (IRB).
    You have full access to the application's models, database, and environment.

    When the user asks you something:
    1. Think about what information you need
    2. Write Ruby code to investigate or solve the problem
    3. Put ALL executable Ruby code in ```ruby fenced code blocks
    4. The code will be eval'd in the console and you'll see the output

    Keep code blocks focused — one logical step per block so results are clear.
    Use `pp` or `puts` for readable output. Avoid long one-liners.
    You can define methods, assign variables — they persist in the session.
  PROMPT

  class << self
    attr_accessor :system_prompt
    attr_writer :cli_path

    # Env vars to clear so claude uses its own stored auth
    def clean_env
      env = {}
      %w[
        ANTHROPIC_API_KEY
        CLAUDE_API_KEY
        CLAUDE_CODE_API_KEY
        CLAUDE_CONFIG_DIR
      ].each { |k| env[k] = nil }
      Array(clear_env_vars).each { |k| env[k] = nil }
      env
    end

    # Additional env vars to clear
    attr_accessor :clear_env_vars

    def cli_path
      @cli_path || "claude"
    end

    def command
      [cli_path, "-p", "--system-prompt", system_prompt || SYSTEM_PROMPT, "--output-format", "text"]
    end
  end
end

# frozen_string_literal: true

require_relative "claude_console/version"

require_relative "claude_console/railtie" if defined?(Rails)

module ClaudeConsole
  SYSTEM_PROMPT = <<~PROMPT
    You are a senior Rails developer pair-programming inside a live Rails console.
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

  def self.environment_context
    lines = []

    if defined?(Rails)
      env = Rails.env
      lines << "Rails environment: #{env}"
      lines << "Rails version: #{Rails.version}"
      lines << "Ruby version: #{RUBY_VERSION}"
      lines << "Application: #{Rails.application.class.module_parent_name}" if Rails.application

      if env.production?
        lines << ""
        lines << "⚠️  PRODUCTION ENVIRONMENT — Exercise extreme caution:"
        lines << "  - DO NOT run destructive operations (delete, destroy, update_all) without explicit user confirmation"
        lines << "  - Prefer read-only queries unless the user specifically asks to mutate data"
        lines << "  - Always scope writes to the smallest possible dataset"
        lines << "  - Show the records that would be affected BEFORE making changes"
      elsif env.staging?
        lines << ""
        lines << "⚠️  STAGING ENVIRONMENT — Be careful with data mutations, this may mirror production."
      end

      if defined?(ActiveRecord::Base)
        db_config = ActiveRecord::Base.connection_db_config
        lines << "Database: #{db_config.adapter}#{db_config.database ? " (#{db_config.database})" : ""}"
      end
    end

    lines.join("\n")
  end

  class << self
    attr_accessor :system_prompt, :session_id
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
      cmd = [cli_path, "-p"]

      if session_id
        cmd.push("--resume", session_id)
      else
        prompt = system_prompt || SYSTEM_PROMPT
        env_ctx = environment_context
        prompt = "#{prompt}\n## Environment\n#{env_ctx}" unless env_ctx.empty?
        cmd.push("--system-prompt", prompt)
      end

      cmd.push("--output-format", "json")
      cmd
    end

    def reset_session!
      @session_id = nil
    end
  end
end

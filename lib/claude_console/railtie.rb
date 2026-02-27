# frozen_string_literal: true

module ClaudeConsole
  class Railtie < Rails::Railtie
    console do
      require "irb"
      require "irb/command"
      require "claude_console/command"
      IRB::Command.register(:claude, ClaudeConsole::Command)
    end
  end
end

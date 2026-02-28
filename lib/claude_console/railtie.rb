# frozen_string_literal: true

module ClaudeConsole
  class Railtie < Rails::Railtie
    console do
      ClaudeConsole.install_transcript!

      if defined?(Pry)
        require "claude_console/pry_command"
        Pry::Commands.add_command(ClaudeConsole::PryCommand)
      else
        require "irb"
        require "irb/command"
        require "claude_console/command"
        IRB::Command.register(:claude, ClaudeConsole::Command)
      end
    end
  end
end

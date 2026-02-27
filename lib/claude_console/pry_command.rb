# frozen_string_literal: true

require "claude_console/command_logic"

module ClaudeConsole
  class PryCommand < Pry::ClassCommand
    include CommandLogic

    match "claude"
    group "Claude"
    description "Pair with Claude in the console (no quotes needed)"

    banner <<~HELP
      Usage: claude <your prompt here>

      Claude can run Ruby code in your session and see the results.

      Examples:
        claude write a function to fix up this user's deliverables
        claude why does User.find(42) have no campaigns
        claude help me debug the email delivery for this tenant
    HELP

    def process(_args)
      prompt = arg_string.to_s.strip
      run_claude(prompt, target)
    end

    private

    def build_context
      lines = []

      if Pry.history.respond_to?(:to_a)
        history = Pry.history.to_a.last(20)
        unless history.empty?
          lines << "Recent console history:"
          history.each { |h| lines << "  >> #{h}" }
        end
      end

      lines.join("\n")
    end
  end
end

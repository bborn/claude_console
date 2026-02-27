# frozen_string_literal: true

require "claude_console/command_logic"

module ClaudeConsole
  class Command < IRB::Command::Base
    include CommandLogic

    category "Claude"
    description "Pair with Claude in the console (no quotes needed)"
    help_message <<~HELP
      Usage: claude <your prompt here>

      Claude can run Ruby code in your session and see the results.

      Examples:
        claude write a function to fix up this user's deliverables
        claude why does User.find(42) have no campaigns
        claude help me debug the email delivery for this tenant
    HELP

    def execute(arg)
      prompt = arg.to_s.strip
      workspace_binding = irb_context.workspace.binding
      run_claude(prompt, workspace_binding)
    end

    private

    def build_context
      lines = []

      if defined?(Reline::HISTORY) && Reline::HISTORY.respond_to?(:to_a)
        history = Reline::HISTORY.to_a.last(20)
        unless history.empty?
          lines << "Recent console history:"
          history.each { |h| lines << "  >> #{h}" }
        end
      end

      lines.join("\n")
    end
  end
end

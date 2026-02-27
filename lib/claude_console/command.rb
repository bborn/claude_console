# frozen_string_literal: true

require "open3"
require "json"

module ClaudeConsole
  class Command < IRB::Command::Base
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
      if prompt.empty?
        puts "Usage: claude <your prompt here>"
        puts "Example: claude help me debug this user's deliverables"
        return
      end

      workspace_binding = irb_context.workspace.binding

      full_prompt = String.new
      context_lines = build_context
      full_prompt << "## Console context\n#{context_lines}\n\n" unless context_lines.empty?
      full_prompt << "## User request\n#{prompt}"

      puts "Asking Claude..."
      puts

      ClaudeConsole.transcript&.pause

      begin
        stdout, stderr, status = Open3.capture3(
          ClaudeConsole.clean_env,
          *ClaudeConsole.command,
          full_prompt
        )

        unless status.success?
          warn "Claude error (exit #{status.exitstatus}):"
          warn stderr unless stderr.empty?
          warn stdout unless stdout.empty?
          return
        end

        text = parse_response(stdout)
        return if text.nil?

        process_response(text, workspace_binding)
      ensure
        ClaudeConsole.transcript&.resume
      end
    end

    private

    def parse_response(stdout)
      data = JSON.parse(stdout)
      ClaudeConsole.session_id = data["session_id"] if data["session_id"]
      data["result"].to_s
    rescue JSON::ParserError
      warn "Failed to parse Claude response"
      nil
    end

    def process_response(response, workspace_binding)
      parts = response.split(/(```ruby\n.*?```)/m)

      parts.each do |part|
        if part.start_with?("```ruby\n")
          code = part.sub("```ruby\n", "").sub(/\n?```\z/, "")
          puts "\e[36m>> Running:\e[0m"
          puts code.gsub(/^/, "   ")
          puts
          begin
            result = workspace_binding.eval(code)
            unless result.nil?
              puts "=> #{result.inspect}"
              puts
            end
          rescue => e
            warn "\e[31mError: #{e.class}: #{e.message}\e[0m"
            puts
          end
        else
          print part unless part.strip.empty?
        end
      end
    end

    def build_context
      transcript = ClaudeConsole.transcript&.flush_transcript
      unless transcript.nil? || transcript.strip.empty?
        return "Console transcript (input + output):\n#{transcript}"
      end

      # Fallback: use input history if transcript capture isn't installed
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

require_relative "lib/claude_console/version"

Gem::Specification.new do |spec|
  spec.name = "claude_console"
  spec.version = ClaudeConsole::VERSION
  spec.summary = "Pair with Claude Code in your Rails console"
  spec.homepage = "https://github.com/bborn/claude_console"
  spec.license = "MIT"
  spec.author = "Bruno Bornsztein"

  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path = "lib"
end

# Claude Console

Pair with [Claude Code](https://claude.ai/claude-code) in your Rails console. No quoting needed.

```ruby
claude help me debug this user's deliverables
claude write a scope to find users with expired trials
claude why does User.find(42) have no campaigns
```

Claude runs Ruby code directly in your console session and sees the results — just like pair programming.

## Installation

Add to your Gemfile:

```ruby
gem "claude_console", group: :development
```

Requires [Claude Code](https://claude.ai/claude-code) installed and authenticated on the machine.

## How It Works

Open `rails console` and type `claude` followed by your request:

```
irb(main):001> claude find the user with email "foo@bar.com" and show their campaigns
Asking Claude...

Here's what I found:

>> Running:
   user = User.find_by(email: "foo@bar.com")

=> #<User id: 42, email: "foo@bar.com">

>> Running:
   pp user.campaigns.select(:id, :name, :status)

[#<Campaign id: 1, name: "Summer 2026", status: "active">,
 #<Campaign id: 2, name: "Fall Launch", status: "draft">]
```

Claude sees your console history for context, runs code in your session, and can iterate on results.

## Configuration

```ruby
# config/initializers/claude_console.rb

# Custom system prompt
ClaudeConsole.system_prompt = "You are a database expert..."

# Path to claude binary
ClaudeConsole.cli_path = "/usr/local/bin/claude"

# Additional env vars to clear (for auth isolation)
ClaudeConsole.clear_env_vars = ["MY_CUSTOM_API_KEY"]
```

## How Auth Works

Claude Console shells out to `claude -p`. It clears env vars like `ANTHROPIC_API_KEY` and `CLAUDE_CONFIG_DIR` from the subprocess so Claude Code uses its own stored credentials — not keys from your Rails environment.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

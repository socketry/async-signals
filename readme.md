# Async::Signals

Composable process signal handling for Ruby.

## Usage

Create one handler set per signal consumer:

```ruby
require "async/signals"

handlers = Async::Signals::Handlers.new
handlers.trap(:INT) do
	puts "Interrupted!"
end

Async::Signals.install(handlers) do
	# Signal handlers are active here.
	sleep
end
```

Multiple handler sets can listen for overlapping signals. `Async::Signals` installs one Ruby signal trap per process signal and fans delivery out to the active handlers.

Use `Async::Signals.reset!` to remove active handlers and restore previous signal traps. On Ruby implementations that support `Process._fork`, `async-signals` automatically resets inherited handlers in forked children.

## Releases

Please see the [project releases](releases.md) for all releases.

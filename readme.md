# Async::Signals

Composable process signal handling for Ruby.

## Usage

Create one subscription per signal consumer:

```ruby
require "async/signals"

subscription = Async::Signals.subscribe
subscription.trap(:INT) do
	puts "Interrupted!"
end

Async::Signals.install(subscription) do
	# Signal traps are active here.
	sleep
end
```

Multiple subscriptions can listen for overlapping signals. `Async::Signals` installs one Ruby signal trap per process signal and fans delivery out to the active subscriptions.

Use `Async::Signals.reset!` to remove active subscriptions and restore previous signal handlers. On Ruby implementations that support `Process._fork`, `async-signals` automatically resets inherited subscriptions in forked children.

## Releases

Please see the [project releases](releases.md) for all releases.

# Getting Started

This guide explains how to use `async-signals` to coordinate process signal handling.

## Usage

Create a subscription:

```ruby
require "async/signals"

subscription = Async::Signals.subscribe

subscription.trap(:TERM) do
	puts "Terminating..."
end

Async::Signals.install(subscription) do
	# Signal traps are active here.
	sleep
end
```

`Async::Signals` owns the process-wide `Signal.trap` entries. Each subscription contributes handlers while installed, allowing multiple consumers to receive overlapping signals without replacing each other's traps.

Use `Async::Signals.reset!` to remove active subscriptions and restore previous signal handlers. On Ruby implementations that support `Process._fork`, `async-signals` automatically resets inherited subscriptions in forked children.

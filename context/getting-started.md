# Getting Started

This guide explains how to use `async-signals` to coordinate process signal handling.

## Usage

Create a handler set:

```ruby
require "async/signals"

handlers = Async::Signals::Handlers.new

handlers.trap(:TERM) do
	puts "Terminating..."
end

Async::Signals.install(handlers) do
	# Signal handlers are active here.
	sleep
end
```

`Async::Signals` owns the process-wide `Signal.trap` entries. Each handler set contributes handlers while installed, allowing multiple consumers to receive overlapping signals without replacing each other's traps.

Signal handlers must be thread safe. Ruby implementations may dispatch signal traps from an implementation-specific thread, so handlers should do minimal work and forward events to a thread-safe mechanism such as `Thread::Queue`.

Use `Async::Signals.reset!` to remove active handlers and restore previous signal traps. On Ruby implementations that support `Process._fork`, `async-signals` automatically resets inherited handlers in forked children.

# Getting Started

This guide explains how to get started with `async-signals`.

## Installation

Add the gem to your project:

```bash
$ bundle add async-signals
```

Then require it in your application:

```ruby
require "async/signals"
```

## Core Concepts

Ruby signal handlers are process-wide. Calling `Signal.trap` for the same signal in two different parts of an application replaces the previous trap, which makes it easy for libraries and application code to accidentally interfere with each other.

`async-signals` provides a small coordination layer around `Signal.trap`:

- {ruby Async::Signals::Handlers} represents a configurable set of signal handlers for one consumer.
- {ruby Async::Signals::Controller} owns the process-wide `Signal.trap` entries while handler sets are installed.
- {ruby Async::Signals.install} installs a handler set using the default process-wide controller.
- {ruby Async::Signals::Ignore} provides a no-op signal backend for code that should not install process signal traps.
- {ruby Async::Signals.reset!} removes all active handlers and restores the previous signal traps.

Each handler set can trap or ignore signals independently. When multiple handler sets trap the same signal, `async-signals` installs one Ruby signal trap and dispatches the signal to each active handler.

## Usage

`async-signals` is useful when multiple parts of the same process need to observe or ignore signals without replacing each other's `Signal.trap` handlers.

### Handling Shutdown Signals

Use a handler set when one part of your application wants to respond to one or more signals without replacing traps installed by other code.

```ruby
require "async/signals"

handlers = Async::Signals::Handlers.new

handlers.trap(:TERM) do |signal|
	puts "Received signal: #{signal}"
end

Async::Signals.install(handlers) do
	# Signal handlers are active here.
	sleep
end
```

When the block exits, the handler set is removed and any previous signal trap is restored.

Handlers may also accept the context that installed the handler set. This is useful when a signal should interrupt the component that installed the handlers, regardless of which thread dispatches the signal trap.

```ruby
handlers.trap(:INT) do |signal, context|
	context.raise(Interrupt)
end
```

### Multiple Consumers

Multiple parts of an application can listen for the same signal. This is useful when a service, supervisor, and application component each need to observe shutdown signals without taking ownership of the process-wide trap.

```ruby
require "async/signals"

supervisor = Async::Signals::Handlers.new
supervisor.trap(:TERM) do
	puts "Stopping supervisor..."
end

application = Async::Signals::Handlers.new
application.trap(:TERM) do
	puts "Stopping application..."
end

Async::Signals.install(supervisor) do
	Async::Signals.install(application) do
		Process.kill(:TERM, Process.pid)
	end
end
```

Both handlers are invoked for the same signal while both handler sets are installed.

### Ignoring Signals

Use {ruby Async::Signals::Handlers#ignore} when one consumer needs a signal to be ignored while it is installed. Ignoring a signal does not suppress handlers installed by other handler sets for the same signal.

```ruby
require "async/signals"

ignored = Async::Signals::Handlers.new
ignored.ignore(:INT)

handled = Async::Signals::Handlers.new
handled.trap(:INT) do
	puts "Still handled by another consumer."
end

Async::Signals.install(ignored) do
	Async::Signals.install(handled) do
		Process.kill(:INT, Process.pid)
	end
end
```

If no active handler set traps the signal, the process-wide trap is set to ignore it for the duration of the installed ignore handler.

### Manual Registration

You can install handlers without a block when the handler lifetime is managed by a longer-lived object. The returned registration can be closed more than once.

```ruby
require "async/signals"

handlers = Async::Signals::Handlers.new
handlers.trap(:HUP) do
	puts "Reloading..."
end

registration = Async::Signals.install(handlers)

begin
	# Run the application.
	sleep
ensure
	registration.close
end
```

The installed handlers are snapshotted when they are installed. Later changes to the handler set do not affect an existing registration.

### Choosing a Signal Backend

Use {ruby Async::Signals.default} when a component should install process signal handlers only when it appears to own the process signal boundary. It returns {ruby Async::Signals} on the main thread when no fiber scheduler is installed, and {ruby Async::Signals::Ignore} otherwise.

```ruby
require "async/signals"

handlers = Async::Signals::Handlers.new
handlers.trap(:TERM) do
	puts "Stopping..."
end

Async::Signals.default.install(handlers) do
	# Process signal handlers are active only when using the default signal backend.
	sleep
end
```

Use {ruby Async::Signals::Ignore} directly when a component is controlled by its parent and should not subscribe to process-wide signals.

### Using Signals with Async

When a component runs inside an existing Async event loop, it should not implicitly take ownership of process-wide signals. In that case, {ruby Async::Signals.default} returns {ruby Async::Signals::Ignore}, so installing handlers through the default backend becomes a no-op.

```ruby
require "async"
require "async/signals"

handlers = Async::Signals::Handlers.new
handlers.trap(:TERM) do
	puts "Stopping..."
end

Async do
	Async::Signals.default.install(handlers) do
		# No process signal traps are installed here.
		sleep
	end
end
```

If a component running inside an Async event loop is intended to own process signal handling, pass {ruby Async::Signals} explicitly instead of using the default backend.

```ruby
require "async"
require "async/signals"

handlers = Async::Signals::Handlers.new
handlers.trap(:TERM) do |signal, context|
	context.raise(Interrupt)
end

Async do
	Async::Signals.install(handlers) do
		# Process signal traps are explicitly installed here.
		sleep
	end
end
```

## Forking

Signal traps are inherited across `fork`. On Ruby implementations that support `Process._fork`, `async-signals` automatically resets inherited signal state in the forked child so the child does not keep handler registrations from the parent process.

If you need to clear all active handler sets explicitly, call:

```ruby
Async::Signals.reset!
```

This restores the process-wide signal traps that were active before `async-signals` installed its handlers.

## Best Practices

Use block-form installation when possible so registrations are closed automatically. Use manual registrations only when another object clearly owns the handler lifetime.

Avoid calling `Signal.trap` for the same signals while `async-signals` handlers are installed. Direct calls to `Signal.trap` replace process-wide traps and can bypass the controller.

Keep signal handlers thread safe. Ruby implementations may dispatch signal traps from an implementation-specific thread, so handlers should avoid mutating shared state directly. Prefer doing minimal work in the handler and forwarding the event to a thread-safe mechanism such as `Thread::Queue`.

Handler exceptions propagate from dispatch. If multiple handler sets observe the same signal and one handler raises, later handlers may not run.

## Troubleshooting

If a handler is not invoked, check that the handler set is installed at the time the signal is delivered. Handler sets are only active inside the `Async::Signals.install` block, or until the returned registration is closed.

If a previous signal trap does not run after installation exits, make sure the registration was closed. Block-form installation handles this automatically.

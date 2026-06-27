# Getting Started

This guide explains how to use `async-signals` to coordinate process signal handling.

## Usage

Create a controller and a subscription:

```ruby
require "async/signals"

controller = Async::Signals::Controller.new
subscription = controller.subscribe

subscription.trap(:TERM) do
	puts "Terminating..."
end

subscription.install do
	# Signal traps are active here.
	sleep
end
```

The controller owns the process-wide `Signal.trap` entries. Each subscription contributes handlers while installed, allowing multiple consumers to receive overlapping signals without replacing each other's traps.

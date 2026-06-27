# Async::Signals

Composable process signal handling for Ruby.

## Usage

Create a process-wide signal controller and one subscription per consumer:

```ruby
require "async/signals"

controller = Async::Signals::Controller.new

subscription = controller.subscribe
subscription.trap(:INT) do
	puts "Interrupted!"
end

subscription.install do
	# Signal traps are active here.
	sleep
end
```

Multiple subscriptions can listen for overlapping signals. The controller installs one Ruby signal trap per process signal and fans delivery out to the active subscriptions.

## Releases

Please see the [project releases](releases.md) for all releases.

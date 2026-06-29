# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Installs default signal handlers for graceful shutdown.
		#
		# Ruby's built-in handling for `SIGINT` can bypass `Thread.handle_interrupt`, which makes graceful shutdown unreliable for event loops and other code that needs to defer interruption while cleaning up. This file also maps `SIGTERM` to `Interrupt`, so both termination signals follow the same graceful shutdown path when they are still using Ruby's default handler.
		#
		# See <https://bugs.ruby-lang.org/issues/22133> for more details.
		module Graceful
			SIGNALS = ["INT", "TERM"].freeze
			
			SIGNALS.each do |signal|
				previous = ::Signal.trap(signal) do
					::Thread.main.raise(::Interrupt)
				end
				
				unless previous == "DEFAULT"
					::Signal.trap(signal, previous)
				end
			end
		end
	end
end

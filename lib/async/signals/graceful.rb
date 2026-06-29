# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../signals"

module Async
	module Signals
		# Registers graceful reset traps for termination signals.
		#
		# After `fork`, {Async::Signals.reset!} clears inherited controller registrations. These reset traps preserve graceful `SIGINT` and `SIGTERM` behavior in forked children without preserving the parent controller's signal subscriptions.
		module Graceful
			Reset.trap(:INT) do
				::Thread.main.raise(::Interrupt)
			end
			
			Reset.trap(:TERM) do
				::Thread.main.raise(::Interrupt)
			end
		end
	end
end

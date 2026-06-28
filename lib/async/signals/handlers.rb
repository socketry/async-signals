# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Represents a configurable set of signal handlers.
		class Handlers
			include Enumerable
			
			# Initialize the handlers.
			def initialize
				@signals = {}
			end
			
			# Trap a signal while these handlers are installed.
			# @parameter signal [Symbol | String | Integer] The signal to trap.
			# @yields {|signal, context| ...} The signal number and the context that installed the handler set.
			def trap(signal, &block)
				@signals[normalize(signal)] = block
			end
			
			# Ignore a signal while these handlers are installed.
			# @parameter signal [Symbol | String | Integer] The signal to ignore.
			def ignore(signal)
				trap(signal)
			end
			
			# Iterate over the configured signal handlers.
			# @yields {|signal, handler| ...} The signal name and the handler, or `nil` if ignored.
			def each(&block)
				@signals.each(&block)
			end
			
			private
			
			# Normalize signals so the controller has one portable key per OS signal.
			# This ensures equivalent forms like `:USR1`, `"USR1"` and `"SIGUSR1"` share
			# the same installed trap and restoration lifecycle.
			def normalize(signal)
				case signal
				when Integer
					::Signal.list.invert.fetch(signal) do
						raise ArgumentError, "unsupported signal number `#{signal}'"
					end
				when Symbol, String
					name = signal.to_s
					name = name.delete_prefix("SIG")
					
					::Signal.list.fetch(name) do
						raise ArgumentError, "unsupported signal `SIG#{name}'"
					end
					
					name
				else
					raise ArgumentError, "bad signal type #{signal.class}"
				end
			end
		end
	end
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Represents a configurable set of signal traps.
		class Subscription
			# Initialize the subscription.
			# @parameter controller [Controller] The controller that will install this subscription.
			def initialize(controller)
				@controller = controller
				@traps = {}
			end
			
			# @attribute [Controller] The controller that will install this subscription.
			attr :controller
			
			# @attribute [Hash(Integer, Proc | Nil)] The configured signal traps.
			attr :traps
			
			# Trap a signal while this subscription is installed.
			# @parameter signal [Symbol | String | Integer] The signal to trap.
			def trap(signal, &block)
				@traps[normalize(signal)] = block
			end
			
			# Ignore a signal while this subscription is installed.
			# @parameter signal [Symbol | String | Integer] The signal to ignore.
			def ignore(signal)
				trap(signal)
			end
			
			# Install this subscription for the duration of the block.
			# @yields {...} The block to run while this subscription is installed.
			def install
				registration = @controller.install(self)
				
				yield self
			ensure
				registration&.close
			end
			
			private
			
			def normalize(signal)
				case signal
				when Integer
					signal
				when Symbol, String
					name = signal.to_s
					name = name.delete_prefix("SIG")
					
					::Signal.list.fetch(name) do
						raise ArgumentError, "unsupported signal `SIG#{name}'"
					end
				else
					raise ArgumentError, "bad signal type #{signal.class}"
				end
			end
		end
	end
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Represents the execution context that installed a signal handler set.
		class Context
			# Initialize the context.
			def initialize
				# Capture both primitives so the public interface can evolve without
				# changing the handler arguments.
				@thread = ::Thread.current
				@fiber = ::Fiber.current
			end
			
			# Raise an exception in the thread that installed the handler set.
			# @parameter arguments [Array] The arguments to pass to {Thread#raise}.
			def raise(*arguments)
				@thread.raise(*arguments)
			end
		end
	end
end

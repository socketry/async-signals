# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Represents the execution context that installed a signal handler set.
		class Context
			# Capture the current execution context.
			# @returns [Context] The current execution context.
			def self.current
				thread = ::Thread.current
				fiber = ::Fiber.current
				scheduler = nil
				
				if ::Fiber.respond_to?(:current_scheduler)
					if current_scheduler = ::Fiber.current_scheduler
						if current_scheduler.respond_to?(:fiber_interrupt)
							scheduler = current_scheduler
						end
					end
				end
				
				self.new(thread, fiber, scheduler)
			end
			
			# Initialize the context.
			# @parameter thread [Thread] The thread that installed the handler set.
			# @parameter fiber [Fiber] The fiber that installed the handler set.
			# @parameter scheduler [Object | Nil] The scheduler that can interrupt the fiber.
			def initialize(thread, fiber, scheduler = nil)
				@thread = thread
				@fiber = fiber
				@scheduler = scheduler
			end
			
			# Raise an exception in the execution context that installed the handler set.
			# @parameter arguments [Array] The arguments to pass to {Thread#raise}.
			def raise(*arguments)
				if @scheduler
					return @scheduler.fiber_interrupt(@fiber, exception_for(arguments))
				end
				
				@thread.raise(*arguments)
			end
			
			private def exception_for(arguments)
				case arguments.size
				when 0
					::RuntimeError.exception
				when 1
					argument = arguments.first
					
					case argument
					when ::String
						::RuntimeError.exception(argument)
					else
						begin
							exception = argument.exception
						rescue NoMethodError
							::Kernel.raise ::TypeError, "exception class/object expected"
						end
						
						unless exception.is_a?(::Exception)
							::Kernel.raise ::TypeError, "exception object expected"
						end
						
						exception
					end
				else
					exception = arguments.first.exception(arguments[1])
					exception.set_backtrace(arguments[2]) if arguments[2]
					exception
				end
			end
		end
	end
end

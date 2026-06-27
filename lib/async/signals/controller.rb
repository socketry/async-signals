# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "thread"

require_relative "handlers"

module Async
	module Signals
		# Coordinates process-wide signal handlers for multiple consumers.
		class Controller
			# Represents the active handlers for a single process signal.
			class State
				# Initialize the signal state.
				# @parameter previous [Object] The signal handler that was installed before this controller took ownership.
				# @parameter handlers [Array(Proc)] The active handlers for the signal.
				# @parameter ignored [Integer] The number of active ignored signals.
				def initialize(previous, handlers = [].freeze, ignored = 0)
					@previous = previous
					@handlers = handlers
					@ignored = ignored
				end
				
				# @attribute [Object] The signal handler that was installed before this controller took ownership.
				attr :previous
				
				# @attribute [Array(Proc)] The active handlers for the signal.
				attr :handlers
				
				# @attribute [Integer] The number of active ignored signals.
				attr :ignored
				
				# Add a signal handler to this state.
				# @parameter handler [Proc | Nil] The handler to add, or `nil` to ignore the signal.
				# @returns [State] The updated state.
				def add(handler)
					if handler
						State.new(@previous, (@handlers + [handler]).freeze, @ignored)
					else
						State.new(@previous, @handlers, @ignored + 1)
					end
				end
				
				# Remove a signal handler from this state.
				# @parameter handler [Proc | Nil] The handler to remove, or `nil` to remove an ignored signal.
				# @returns [State] The updated state.
				def remove(handler)
					if handler
						handlers = @handlers.dup
						
						if index = handlers.index(handler)
							handlers.delete_at(index)
						end
						
						State.new(@previous, handlers.freeze, @ignored)
					else
						State.new(@previous, @handlers, @ignored - 1)
					end
				end
				
				# Whether this state has any active handlers.
				# @returns [Boolean] True if no handlers or ignored signals are active.
				def empty?
					@handlers.empty? && @ignored.zero?
				end
			end
			
			# Represents an installed set of signal handlers.
			class Registration
				# Initialize the registration.
				# @parameter controller [Controller] The controller that owns this registration.
				# @parameter handlers [Hash(Integer, Proc | Nil)] The handlers that were installed.
				def initialize(controller, handlers)
					@controller = controller
					@handlers = handlers
				end
				
				# Remove this registration from the controller.
				def close
					if handlers = @handlers
						@handlers = nil
						@controller.remove(handlers)
					end
				end
			end
			
			# Initialize the controller.
			def initialize
				@mutex = ::Thread::Mutex.new
				@states = {}
				@dispatch = {}.freeze
			end
			
			# Install signal handlers.
			# @parameter handlers [Handlers] The handlers to install.
			# @yields {|handlers| ...} The block to run while the handlers are installed.
			# @returns [Registration] The active registration.
			def install(handlers)
				installed_handlers = handlers.to_h.freeze
				
				@mutex.synchronize do
					installed_handlers.each do |signal, handler|
						add(signal, handler)
					end
					
					update_dispatch
				end
				
				registration = Registration.new(self, installed_handlers)
				
				if block_given?
					begin
						return yield handlers
					ensure
						registration.close
					end
				else
					return registration
				end
			end
			
			# Dispatch a signal to all currently active handlers.
			# @parameter signal [Integer] The signal number to dispatch.
			def dispatch(signal)
				errors = nil
				
				@dispatch[signal]&.each do |handler|
					begin
						handler.call(signal)
					rescue Exception => error
						(errors ||= []) << error
					end
				end
				
				if errors
					raise errors.first
				end
			end
			
			# Remove a set of installed handlers.
			# @parameter handlers [Hash(Integer, Proc | Nil)] The handlers to remove.
			def remove(handlers)
				@mutex.synchronize do
					handlers.each do |signal, handler|
						remove_signal(signal, handler)
					end
					
					update_dispatch
				end
			end
			
			# Reset all installed signal handlers to their previous signal traps.
			def reset!
				@mutex.synchronize do
					@states.each do |signal, state|
						::Signal.trap(signal, state.previous)
					end
					
					@states.clear
					update_dispatch
				end
			end
			
			private
			
			def add(signal, handler)
				unless state = @states[signal]
					previous = ::Signal.trap(signal, "IGNORE")
					state = State.new(previous)
				end
				
				@states[signal] = state.add(handler)
				
				update_signal(signal)
			end
			
			def remove_signal(signal, handler)
				if state = @states[signal]
					state = state.remove(handler)
					
					if state.empty?
						::Signal.trap(signal, state.previous)
						@states.delete(signal)
					else
						@states[signal] = state
						update_signal(signal)
					end
				end
			end
			
			def update_signal(signal)
				state = @states.fetch(signal)
				
				if state.handlers.empty?
					::Signal.trap(signal, "IGNORE")
				else
					::Signal.trap(signal) do
						self.dispatch(signal)
					end
				end
			end
			
			def update_dispatch
				@dispatch = @states.each_with_object({}) do |(signal, state), dispatch|
					unless state.handlers.empty?
						dispatch[signal] = state.handlers
					end
				end.freeze
			end
		end
	end
end

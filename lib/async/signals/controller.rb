# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "thread"

require_relative "subscription"

module Async
	module Signals
		# Coordinates process-wide signal traps for multiple subscribers.
		class Controller
			# Represents the active handlers for a single process signal.
			class State
				# Initialize the signal state.
				# @parameter previous [Object] The signal handler that was installed before this controller took ownership.
				# @parameter handlers [Array(Proc)] The active handlers for the signal.
				# @parameter ignored [Integer] The number of active ignore subscriptions.
				def initialize(previous, handlers = [].freeze, ignored = 0)
					@previous = previous
					@handlers = handlers
					@ignored = ignored
				end
				
				# @attribute [Object] The signal handler that was installed before this controller took ownership.
				attr :previous
				
				# @attribute [Array(Proc)] The active handlers for the signal.
				attr :handlers
				
				# @attribute [Integer] The number of active ignore subscriptions.
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
				# @parameter handler [Proc | Nil] The handler to remove, or `nil` to remove an ignore subscription.
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
				
				# Whether this state has any active subscriptions.
				# @returns [Boolean] True if no handlers or ignore subscriptions are active.
				def empty?
					@handlers.empty? && @ignored.zero?
				end
			end
			
			# Represents an installed set of signal handlers.
			class Registration
				# Initialize the registration.
				# @parameter controller [Controller] The controller that owns this registration.
				# @parameter traps [Hash(Integer, Proc | Nil)] The traps that were installed.
				def initialize(controller, traps)
					@controller = controller
					@traps = traps
				end
				
				# Remove this registration from the controller.
				def close
					if traps = @traps
						@traps = nil
						@controller.remove(traps)
					end
				end
			end
			
			# Initialize the controller.
			def initialize
				@mutex = ::Thread::Mutex.new
				@states = {}
				@dispatch = {}.freeze
			end
			
			# Create a new signal subscription.
			# @returns [Subscription] The new subscription.
			def subscribe
				Subscription.new(self)
			end
			
			# Install a subscription.
			# @parameter subscription [Subscription] The subscription to install.
			# @returns [Registration] The active registration.
			def install(subscription)
				traps = subscription.traps.dup.freeze
				
				@mutex.synchronize do
					traps.each do |signal, handler|
						add(signal, handler)
					end
					
					update_dispatch
				end
				
				return Registration.new(self, traps)
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
			
			# Remove a set of installed traps.
			# @parameter traps [Hash(Integer, Proc | Nil)] The traps to remove.
			def remove(traps)
				@mutex.synchronize do
					traps.each do |signal, handler|
						remove_signal(signal, handler)
					end
					
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

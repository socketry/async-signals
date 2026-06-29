# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "thread"

require_relative "handlers"

module Async
	module Signals
		# Defines signal traps restored by {Async::Signals.reset!}.
		module Reset
			MUTEX = ::Thread::Mutex.new
			@handlers = Handlers.new
			
			# Trap a signal after {Async::Signals.reset!}.
			# @parameter signal [Symbol | String | Integer] The signal to trap.
			def self.trap(signal, &block)
				MUTEX.synchronize do
					@handlers.trap(signal, &block)
				end
			end
			
			# The signal traps restored after reset.
			# @returns [Hash(String, Proc | Nil)] The configured reset traps.
			def self.to_h
				MUTEX.synchronize do
					@handlers.to_h.freeze
				end
			end
			
			# Clear all reset traps.
			def self.clear
				MUTEX.synchronize do
					@handlers = Handlers.new
				end
			end
		end
	end
end

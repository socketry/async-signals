# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "signals/version"
require_relative "signals/context"
require_relative "signals/handlers"
require_relative "signals/reset"
require_relative "signals/controller"
require_relative "signals/ignore"

module Async
	# Provides composable process signal handling.
	module Signals
		CONTROLLER = Controller.new
		
		# The default process-wide signal controller.
		# @returns [Controller] The default signal controller.
		def self.controller
			CONTROLLER
		end
		
		# The default signal backend for the current context.
		# @returns [Async::Signals | Async::Signals::Ignore] The default signal backend.
		def self.default
			if ::Thread.current == ::Thread.main
				# TruffleRuby does not currently expose `Fiber.scheduler`:
				unless ::Fiber.respond_to?(:scheduler) && ::Fiber.scheduler
					return self
				end
			end
			
			return Ignore
		end
		
		# Install signal handlers using the process-wide signal controller.
		# @parameter handlers [Handlers] The handlers to install.
		# @returns [Controller::Registration] The active registration.
		def self.install(handlers, &block)
			CONTROLLER.install(handlers, &block)
		end
		
		# Reset the process-wide signal controller.
		# @returns [void]
		def self.reset!
			CONTROLLER.reset!
		end
		
		if ::Process.respond_to?(:_fork)
			# Resets inherited signal state in forked children.
			module ForkHook
				# Fork the current process and reset inherited signal state in the child.
				def _fork
					pid = super
					
					if pid == 0
						Async::Signals.reset!
					end
					
					return pid
				end
			end
			
			::Process.singleton_class.prepend(ForkHook)
		end
	end
end

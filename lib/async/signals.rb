# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "signals/version"
require_relative "signals/subscription"
require_relative "signals/controller"

# @namespace
module Async
	# Provides composable process signal handling.
	module Signals
		CONTROLLER = Controller.new
		
		# The default process-wide signal controller.
		# @returns [Controller] The default signal controller.
		def self.controller
			CONTROLLER
		end
		
		# Create a new signal subscription.
		# @returns [Subscription] The new subscription.
		def self.subscribe
			Subscription.new
		end
		
		# Install a subscription using the process-wide signal controller.
		# @parameter subscription [Subscription] The subscription to install.
		# @returns [Controller::Registration] The active registration.
		def self.install(subscription, &block)
			CONTROLLER.install(subscription, &block)
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

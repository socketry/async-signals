# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		# Provides a no-op signal backend.
		module Ignore
			# Represents a no-op signal registration.
			class Registration
				# Close the registration.
				def close
				end
			end
			
			REGISTRATION = Registration.new.freeze
			
			# Ignore signal handlers.
			# @parameter handlers [Handlers] The handlers to ignore.
			# @returns [Registration] The no-op registration.
			def self.install(handlers)
				if block_given?
					yield handlers
				else
					REGISTRATION
				end
			end
		end
	end
end

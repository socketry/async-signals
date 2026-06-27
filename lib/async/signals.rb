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
		INSTANCE = Controller.new
		
		# The default process-wide signal controller.
		# @returns [Controller] The default signal controller.
		def self.instance
			INSTANCE
		end
	end
end

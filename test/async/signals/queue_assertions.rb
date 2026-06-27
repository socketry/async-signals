# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Async
	module Signals
		module QueueAssertions
			def expect_event(queue, timeout: 1)
				expect(queue.pop(timeout: timeout))
			end
			
			def expect_no_event(queue, timeout: 0.1)
				expect(queue.pop(timeout: timeout)).to be_nil
			end
		end
	end
end

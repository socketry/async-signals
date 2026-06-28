# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/context"

describe Async::Signals::Context do
	let(:context) {subject.new}
	
	with "#raise" do
		it "raises in the captured thread" do
			expect do
				context.raise(RuntimeError, "interrupted")
			end.to raise_exception(RuntimeError, message: be == "interrupted")
		end
	end
end

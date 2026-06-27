# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals"

describe Async::Signals do
	it "has a version number" do
		expect(subject::VERSION).to be_a(String)
	end
	
	with ".instance" do
		it "returns the default signal controller" do
			expect(subject.instance).to be_a(subject::Controller)
			expect(subject.instance).to be == subject.instance
		end
	end
end

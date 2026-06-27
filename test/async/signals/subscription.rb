# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/controller"
require "async/signals/subscription"

describe Async::Signals::Subscription do
	let(:subscription) {subject.new}
	
	with "#trap" do
		it "normalizes symbolic signal names" do
			handler = proc{}
			
			subscription.trap(:USR1, &handler)
			
			expect(subscription.traps).to have_keys(
				::Signal.list.fetch("USR1") => be == handler
			)
		end
		
		it "normalizes string signal names" do
			handler = proc{}
			
			subscription.trap("SIGUSR1", &handler)
			
			expect(subscription.traps).to have_keys(
				::Signal.list.fetch("USR1") => be == handler
			)
		end
		
		it "stores nil for ignored signals" do
			subscription.trap(:USR1)
			
			expect(subscription.traps).to have_keys(
				::Signal.list.fetch("USR1") => be_nil
			)
		end
	end
end

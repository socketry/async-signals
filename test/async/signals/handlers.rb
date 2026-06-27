# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/controller"
require "async/signals/handlers"

describe Async::Signals::Handlers do
	let(:handlers) {subject.new}
	
	with "#trap" do
		it "normalizes symbolic signal names" do
			handler = proc{}
			
			handlers.trap(:USR1, &handler)
			
			expect(handlers.to_h).to have_keys(
				::Signal.list.fetch("USR1") => be == handler
			)
		end
		
		it "normalizes string signal names" do
			handler = proc{}
			
			handlers.trap("SIGUSR1", &handler)
			
			expect(handlers.to_h).to have_keys(
				::Signal.list.fetch("USR1") => be == handler
			)
		end
		
		it "stores nil for ignored signals" do
			handlers.trap(:USR1)
			
			expect(handlers.to_h).to have_keys(
				::Signal.list.fetch("USR1") => be_nil
			)
		end
	end
end

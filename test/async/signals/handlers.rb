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
		
		it "normalizes integer signal names" do
			handler = proc{}
			signal = ::Signal.list.fetch("USR1")
			
			handlers.trap(signal, &handler)
			
			expect(handlers.to_h).to have_keys(
				signal => be == handler
			)
		end
		
		it "rejects unsupported signal names" do
			expect do
				handlers.trap(:UNSUPPORTED)
			end.to raise_exception(ArgumentError, message: be =~ /unsupported signal/)
		end
		
		it "rejects unsupported signal types" do
			expect do
				handlers.trap(Object.new)
			end.to raise_exception(ArgumentError, message: be =~ /bad signal type/)
		end
	end
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals"

require_relative "queue_assertions"

describe Async::Signals::Ignore do
	include Async::Signals::QueueAssertions
	
	it "returns the block result" do
		handlers = Async::Signals::Handlers.new
		
		expect(subject.install(handlers){:result}).to be == :result
	end
	
	it "returns a no-op registration" do
		handlers = Async::Signals::Handlers.new
		registration = subject.install(handlers)
		
		expect(registration).to be_a(subject::Registration)
		
		expect do
			registration.close
		end.not.to raise_exception
	end
	
	it "does not install signal handlers" do
		events = ::Thread::Queue.new
		original = ::Signal.trap(:USR1) do
			events << :handled
		end
		
		begin
			handlers = Async::Signals::Handlers.new
			
			handlers.ignore(:USR1)
			
			subject.install(handlers) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect_event(events).to be == :handled
			end
		ensure
			::Signal.trap(:USR1, original)
		end
	end
end

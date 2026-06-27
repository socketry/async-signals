# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/controller"
require "async/signals/subscription"

describe Async::Signals::Controller do
	let(:controller) {subject.new}
	
	it "can deliver one signal to one subscription" do
		events = ::Thread::Queue.new
		subscription = controller.subscribe
		
		subscription.trap(:USR1) do |signal|
			events << signal
		end
		
		controller.install(subscription) do
			::Process.kill(:USR1, ::Process.pid)
			
			expect(events.pop).to be == ::Signal.list.fetch("USR1")
		end
	end
	
	it "can deliver overlapping signals to multiple subscriptions" do
		first = ::Thread::Queue.new
		second = ::Thread::Queue.new
		
		first_subscription = controller.subscribe
		first_subscription.trap(:USR1) do |signal|
			first << signal
		end
		
		second_subscription = controller.subscribe
		second_subscription.trap(:USR1) do |signal|
			second << signal
		end
		
		controller.install(first_subscription) do
			controller.install(second_subscription) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect(first.pop).to be == ::Signal.list.fetch("USR1")
				expect(second.pop).to be == ::Signal.list.fetch("USR1")
			end
		end
	end
	
	it "can deliver different signals to different subscriptions" do
		first = ::Thread::Queue.new
		second = ::Thread::Queue.new
		
		first_subscription = controller.subscribe
		first_subscription.trap(:USR1) do |signal|
			first << signal
		end
		
		second_subscription = controller.subscribe
		second_subscription.trap(:USR2) do |signal|
			second << signal
		end
		
		controller.install(first_subscription) do
			controller.install(second_subscription) do
				::Process.kill(:USR1, ::Process.pid)
				expect(first.pop).to be == ::Signal.list.fetch("USR1")
				
				::Process.kill(:USR2, ::Process.pid)
				expect(second.pop).to be == ::Signal.list.fetch("USR2")
				
				expect do
					first.pop(true)
				end.to raise_exception(ThreadError)
			end
		end
	end
	
	it "can ignore a signal" do
		subscription = controller.subscribe
		subscription.ignore(:USR1)
		
		controller.install(subscription) do
			expect do
				::Process.kill(:USR1, ::Process.pid)
			end.not.to raise_exception
		end
	end
	
	it "does not let ignore suppress another subscription" do
		events = ::Thread::Queue.new
		
		ignored = controller.subscribe
		ignored.ignore(:USR1)
		
		handled = controller.subscribe
		handled.trap(:USR1) do |signal|
			events << signal
		end
		
		controller.install(ignored) do
			controller.install(handled) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect(events.pop).to be == ::Signal.list.fetch("USR1")
			end
		end
	end
	
	it "can close a registration more than once" do
		subscription = controller.subscribe
		subscription.ignore(:USR1)
		
		registration = controller.install(subscription)
		
		expect do
			registration.close
			registration.close
		end.not.to raise_exception
	end
	
	it "returns the block result when installing a subscription" do
		subscription = controller.subscribe
		
		expect(controller.install(subscription){:result}).to be == :result
	end
	
	it "uses a snapshot of the subscription traps" do
		events = ::Thread::Queue.new
		original = ::Signal.trap(:USR1, "IGNORE")
		
		begin
			subscription = controller.subscribe
			subscription.trap(:USR1) do |signal|
				events << signal
			end
			
			registration = controller.install(subscription)
			subscription.ignore(:USR1)
			
			registration.close
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect do
				events.pop(true)
			end.to raise_exception(ThreadError)
		ensure
			::Signal.trap(:USR1, original)
		end
	end
	
	it "propagates handler errors" do
		error = RuntimeError.new("handler failed")
		
		subscription = controller.subscribe
		subscription.trap(:USR1) do
			raise error
		end
		
		controller.install(subscription) do
			expect do
				::Process.kill(:USR1, ::Process.pid)
			end.to raise_exception(RuntimeError)
		end
	end
	
	it "restores previous signal handlers" do
		previous = ::Thread::Queue.new
		original = ::Signal.trap(:USR1) do
			previous << :handled
		end
		
		begin
			subscription = controller.subscribe
			subscription.ignore(:USR1)
			
			controller.install(subscription) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect do
					previous.pop(true)
				end.to raise_exception(ThreadError)
			end
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect(previous.pop).to be == :handled
		ensure
			::Signal.trap(:USR1, original)
		end
	end
end

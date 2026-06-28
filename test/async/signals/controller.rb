# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/controller"
require "async/signals/handlers"

require_relative "queue_assertions"

describe Async::Signals::Controller do
	include Async::Signals::QueueAssertions
	
	let(:controller) {subject.new}
	
	it "can deliver one signal to one handler set" do
		events = ::Thread::Queue.new
		handlers = Async::Signals::Handlers.new
		
		handlers.trap(:USR1) do |signal|
			events << signal
		end
		
		controller.install(handlers) do
			::Process.kill(:USR1, ::Process.pid)
			
			expect_event(events).to be == ::Signal.list.fetch("USR1")
		end
	end
	
	it "can deliver overlapping signals to multiple handler sets" do
		first = ::Thread::Queue.new
		second = ::Thread::Queue.new
		
		first_handlers = Async::Signals::Handlers.new
		first_handlers.trap(:USR1) do |signal|
			first << signal
		end
		
		second_handlers = Async::Signals::Handlers.new
		second_handlers.trap(:USR1) do |signal|
			second << signal
		end
		
		controller.install(first_handlers) do
			controller.install(second_handlers) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect_event(first).to be == ::Signal.list.fetch("USR1")
				expect_event(second).to be == ::Signal.list.fetch("USR1")
			end
		end
	end
	
	it "passes the installing context to handlers" do
		exception = Class.new(StandardError)
		events = ::Thread::Queue.new
		ready = ::Thread::Queue.new
		release = ::Thread::Queue.new
		
		handlers = Async::Signals::Handlers.new
		handlers.trap(:USR1) do |signal, context|
			events << signal
			context.raise(exception)
		end
		
		thread = ::Thread.new do
			begin
				controller.install(handlers) do
					ready << true
					release.pop
				end
			rescue exception
				events << :interrupted
			end
		end
		
		begin
			ready.pop(timeout: 1)
			
			controller.dispatch("USR1")
			
			expect_event(events).to be == ::Signal.list.fetch("USR1")
			expect_event(events).to be == :interrupted
		ensure
			release << nil
			thread.join(1)
			thread.kill if thread.alive?
		end
	end
	
	it "can deliver different signals to different handler sets" do
		first = ::Thread::Queue.new
		second = ::Thread::Queue.new
		
		first_handlers = Async::Signals::Handlers.new
		first_handlers.trap(:USR1) do |signal|
			first << signal
		end
		
		second_handlers = Async::Signals::Handlers.new
		second_handlers.trap(:USR2) do |signal|
			second << signal
		end
		
		controller.install(first_handlers) do
			controller.install(second_handlers) do
				::Process.kill(:USR1, ::Process.pid)
				expect_event(first).to be == ::Signal.list.fetch("USR1")
				
				::Process.kill(:USR2, ::Process.pid)
				expect_event(second).to be == ::Signal.list.fetch("USR2")
				
				expect_no_event(first)
			end
		end
	end
	
	it "can ignore a signal" do
		handlers = Async::Signals::Handlers.new
		handlers.ignore(:USR1)
		
		controller.install(handlers) do
			expect do
				::Process.kill(:USR1, ::Process.pid)
			end.not.to raise_exception
		end
	end
	
	it "does not let ignore suppress another handler set" do
		events = ::Thread::Queue.new
		
		ignored = Async::Signals::Handlers.new
		ignored.ignore(:USR1)
		
		handled = Async::Signals::Handlers.new
		handled.trap(:USR1) do |signal|
			events << signal
		end
		
		controller.install(ignored) do
			controller.install(handled) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect_event(events).to be == ::Signal.list.fetch("USR1")
			end
		end
	end
	
	it "keeps a signal ignored until all ignored registrations are closed" do
		events = ::Thread::Queue.new
		original = ::Signal.trap(:USR1) do
			events << :handled
		end
		
		begin
			first = Async::Signals::Handlers.new
			first.ignore(:USR1)
			
			second = Async::Signals::Handlers.new
			second.ignore(:USR1)
			
			first_registration = controller.install(first)
			second_registration = controller.install(second)
			
			first_registration.close
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect_no_event(events)
			
			second_registration.close
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect_event(events).to be == :handled
		ensure
			::Signal.trap(:USR1, original)
		end
	end
	
	it "can close a registration more than once" do
		handlers = Async::Signals::Handlers.new
		handlers.ignore(:USR1)
		
		registration = controller.install(handlers)
		
		expect do
			registration.close
			registration.close
		end.not.to raise_exception
	end
	
	it "returns the block result when installing handlers" do
		handlers = Async::Signals::Handlers.new
		
		expect(controller.install(handlers){:result}).to be == :result
	end
	
	it "uses a snapshot of the handlers" do
		events = ::Thread::Queue.new
		original = ::Signal.trap(:USR1, "IGNORE")
		
		begin
			handlers = Async::Signals::Handlers.new
			handlers.trap(:USR1) do |signal|
				events << signal
			end
			
			registration = controller.install(handlers)
			handlers.ignore(:USR1)
			
			registration.close
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect_no_event(events)
		ensure
			::Signal.trap(:USR1, original)
		end
	end
	
	it "removes handlers by registration identity" do
		events = ::Thread::Queue.new
		handler = proc do |signal|
			events << signal
		end
		
		first_handlers = Async::Signals::Handlers.new
		first_handlers.trap(:USR1, &handler)
		
		second_handlers = Async::Signals::Handlers.new
		second_handlers.trap(:USR1, &handler)
		
		first_registration = controller.install(first_handlers)
		second_registration = controller.install(second_handlers)
		
		begin
			first_registration.close
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect_event(events).to be == ::Signal.list.fetch("USR1")
			
			expect_no_event(events)
		ensure
			second_registration.close
		end
	end
	
	it "propagates handler errors" do
		error = RuntimeError.new("handler failed")
		
		failing_handlers = Async::Signals::Handlers.new
		failing_handlers.trap(:USR1) do
			raise error
		end
		
		controller.install(failing_handlers) do
			expect do
				controller.dispatch("USR1")
			end.to raise_exception(RuntimeError, message: be == error.message)
		end
	end
	
	it "restores previous signal handlers" do
		previous = ::Thread::Queue.new
		original = ::Signal.trap(:USR1) do
			previous << :handled
		end
		
		begin
			handlers = Async::Signals::Handlers.new
			handlers.ignore(:USR1)
			
			controller.install(handlers) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect_no_event(previous)
			end
			
			::Process.kill(:USR1, ::Process.pid)
			
			expect_event(previous).to be == :handled
		ensure
			::Signal.trap(:USR1, original)
		end
	end
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/context"

describe Async::Signals::Context do
	let(:context) {subject.new(::Thread.current, ::Fiber.current)}
	
	def make_scheduler
		scheduler = Object.new
		events = self.events
		
		scheduler.define_singleton_method(:block) do |*|
		end
		
		scheduler.define_singleton_method(:unblock) do |*|
		end
		
		scheduler.define_singleton_method(:kernel_sleep) do |*|
		end
		
		scheduler.define_singleton_method(:io_wait) do |*|
		end
		
		scheduler.define_singleton_method(:fiber_interrupt) do |fiber, exception|
			events << [fiber, exception]
		end
		
		scheduler
	end
	
	let(:events) {[]}
	let(:scheduler) {make_scheduler}
	
	def with_scheduler
		previous_scheduler = ::Fiber.scheduler
		::Fiber.set_scheduler(scheduler)
		
		yield scheduler, events
	ensure
		::Fiber.set_scheduler(previous_scheduler)
	end
	
	with ".current" do
		it "captures the current thread and fiber" do
			context = subject.current
			
			expect do
				context.raise(RuntimeError, "interrupted")
			end.to raise_exception(RuntimeError, message: be == "interrupted")
		end
		
		it "captures the current scheduler from a non-blocking fiber" do
			skip "Fiber.current_scheduler is not supported." unless ::Fiber.respond_to?(:current_scheduler) && ::Fiber.respond_to?(:set_scheduler)
			
			with_scheduler do |scheduler, events|
				fiber = ::Fiber.new(blocking: false) do
					expect(::Fiber.current_scheduler).to be == scheduler
					
					context = subject.current
					context.raise(RuntimeError, "interrupted")
				end
				
				fiber.resume
				
				expect(events.size).to be == 1
				expect(events.first[0]).to be == fiber
				expect(events.first[1]).to be_a(RuntimeError)
				expect(events.first[1].message).to be == "interrupted"
			end
		end
	end
	
	with "#raise" do
		it "raises in the captured thread" do
			expect do
				context.raise(RuntimeError, "interrupted")
			end.to raise_exception(RuntimeError, message: be == "interrupted")
		end
		
		it "converts string arguments to runtime errors" do
			expect do
				context.raise("interrupted")
			end.to raise_exception(RuntimeError, message: be == "interrupted")
		end
		
		it "rejects invalid exception arguments" do
			expect do
				context.raise(Object.new)
			end.to raise_exception(TypeError, message: be =~ /exception class\/object expected/)
		end
		
		it "converts raise arguments for fiber interruption" do
			backtrace = ["example.rb:1"]
			context = subject.new(::Thread.current, ::Fiber.current, scheduler)
			
			context.raise
			context.raise("message")
			context.raise(Interrupt)
			
			context.raise(RuntimeError, "interrupted", backtrace)
			
			expect do
				context.raise(Object.new)
			end.to raise_exception(TypeError, message: be =~ /exception class\/object expected/)
			
			invalid = Object.new
			invalid.define_singleton_method(:exception){Object.new}
			
			expect do
				context.raise(invalid)
			end.to raise_exception(TypeError, message: be =~ /exception object expected/)
			
			expect(events[0][1]).to be_a(RuntimeError)
			expect(events[1][1]).to be_a(RuntimeError)
			expect(events[1][1].message).to be == "message"
			expect(events[2][1]).to be_a(Interrupt)
			expect(events[3][1]).to be_a(RuntimeError)
			expect(events[3][1].message).to be == "interrupted"
			expect(events[3][1].backtrace).to be == backtrace
		end
	end
end

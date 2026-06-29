# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals"
require "rbconfig"

require_relative "signals/queue_assertions"

describe Async::Signals do
	include Async::Signals::QueueAssertions
	
	def make_scheduler
		Object.new.tap do |scheduler|
			scheduler.define_singleton_method(:block) do |*|
			end
			
			scheduler.define_singleton_method(:unblock) do |*|
			end
			
			scheduler.define_singleton_method(:kernel_sleep) do |*|
			end
			
			scheduler.define_singleton_method(:io_wait) do |*|
			end
			
			scheduler.define_singleton_method(:fiber_interrupt) do |*|
			end
		end
	end
	
	def with_scheduler
		previous_scheduler = ::Fiber.scheduler
		::Fiber.set_scheduler(make_scheduler)
		
		yield
	ensure
		::Fiber.set_scheduler(previous_scheduler)
	end
	
	it "has a version number" do
		expect(subject::VERSION).to be_a(String)
	end
	
	with ".controller" do
		it "returns the default signal controller" do
			expect(subject.controller).to be_a(subject::Controller)
			expect(subject.controller).to be == subject.controller
		end
	end
	
	with ".default" do
		it "returns process signals on the main thread without a scheduler" do
			expect(subject.default).to be == subject
		end
		
		it "ignores process signals outside the top level" do
			default = ::Thread.new do
				subject.default
			end.value
			
			expect(default).to be == subject::Ignore
		end
		
		it "ignores process signals when a scheduler is installed" do
			skip "Fiber.set_scheduler is not supported." unless ::Fiber.respond_to?(:set_scheduler)
			
			with_scheduler do
				expect(subject.default).to be == subject::Ignore
			end
		end
	end
	
	with ".install" do
		it "installs handlers using the default controller" do
			events = ::Thread::Queue.new
			handlers = subject::Handlers.new
			
			handlers.trap(:USR1) do |signal|
				events << signal
			end
			
			subject.install(handlers) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect_event(events).to be == ::Signal.list.fetch("USR1")
			end
		end
		
		it "returns the block result" do
			handlers = subject::Handlers.new
			
			expect(subject.install(handlers){:result}).to be == :result
		end
	end
	
	with ".reset!" do
		it "removes installed handlers from the default controller" do
			events = ::Thread::Queue.new
			original = ::Signal.trap(:USR1, "IGNORE")
			
			begin
				handlers = subject::Handlers.new
				
				handlers.trap(:USR1) do |signal|
					events << signal
				end
				
				registration = subject.install(handlers)
				
				subject.reset!
				
				::Process.kill(:USR1, ::Process.pid)
				
				expect_no_event(events)
				
				registration.close
			ensure
				::Signal.trap(:USR1, original)
			end
		end
		
		it "is invoked by the fork hook" do
			skip "Process._fork is not supported." unless defined?(subject::ForkHook)
			
			process = Class.new do
				def _fork
					0
				end
			end
			
			process.prepend(subject::ForkHook)
			
			mock(subject) do |mock|
				mock.replace(:reset!) do
					:reset
				end
				
				expect(process.new._fork).to be == 0
			end
		end
		
		it "is invoked after fork" do
			skip "Process._fork is not supported." unless ::Process.respond_to?(:_fork)
			
			script = <<~RUBY
				require "async/signals"
				
				input, output = IO.pipe
				Signal.trap(:USR1, "IGNORE")
				
				handlers = Async::Signals::Handlers.new
				handlers.trap(:USR1) do
					output.write("handled")
					output.flush
				end
				
				Async::Signals.install(handlers) do
					pid = Process.fork do
						input.close
						
						Process.kill(:USR1, Process.pid)
						
						output.close
						exit!(0)
					end
					
					output.close
					Process.wait(pid)
					
					exit!(input.read.empty? ? 0 : 1)
				end
			RUBY
			
			expect(system(::RbConfig.ruby, "-Ilib", "-e", script)).to be == true
		end
		
		it "restores reset traps after fork" do
			skip "Process._fork is not supported." unless ::Process.respond_to?(:_fork)
			
			script = <<~RUBY
				require "async/signals"
				
				input, output = IO.pipe
				
				Async::Signals::Reset.trap(:USR1) do
					output.write("handled")
					output.flush
				end
				
				pid = Process.fork do
					input.close
					
					Process.kill(:USR1, Process.pid)
					
					output.close
					exit!(0)
				end
				
				output.close
				Process.wait(pid)
				
				exit!(input.read == "handled" ? 0 : 1)
			RUBY
			
			expect(system(::RbConfig.ruby, "-Ilib", "-e", script)).to be == true
		end
	end
end

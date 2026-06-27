# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals"
require "rbconfig"

describe Async::Signals do
	it "has a version number" do
		expect(subject::VERSION).to be_a(String)
	end
	
	with ".controller" do
		it "returns the default signal controller" do
			expect(subject.controller).to be_a(subject::Controller)
			expect(subject.controller).to be == subject.controller
		end
	end
	
	with ".subscribe" do
		it "creates a subscription" do
			expect(subject.subscribe).to be_a(subject::Subscription)
		end
	end
	
	with ".install" do
		it "installs a subscription using the default controller" do
			events = ::Thread::Queue.new
			subscription = subject.subscribe
			
			subscription.trap(:USR1) do |signal|
				events << signal
			end
			
			subject.install(subscription) do
				::Process.kill(:USR1, ::Process.pid)
				
				expect(events.pop).to be == ::Signal.list.fetch("USR1")
			end
		end
		
		it "returns the block result" do
			subscription = subject.subscribe
			
			expect(subject.install(subscription){:result}).to be == :result
		end
	end
	
	with ".reset!" do
		it "removes installed subscriptions from the default controller" do
			events = ::Thread::Queue.new
			original = ::Signal.trap(:USR1, "IGNORE")
			
			begin
				subscription = subject.subscribe
				
				subscription.trap(:USR1) do |signal|
					events << signal
				end
				
				registration = subject.install(subscription)
				
				subject.reset!
				
				::Process.kill(:USR1, ::Process.pid)
				
				expect do
					events.pop(true)
				end.to raise_exception(ThreadError)
				
				registration.close
			ensure
				::Signal.trap(:USR1, original)
			end
		end
		
		it "is invoked after fork" do
			skip "Process._fork is not supported." unless ::Process.respond_to?(:_fork)
			
			script = <<~RUBY
				require "async/signals"
				
				input, output = IO.pipe
				Signal.trap(:USR1, "IGNORE")
				
				subscription = Async::Signals.subscribe
				subscription.trap(:USR1) do
					output.write("handled")
					output.flush
				end
				
				Async::Signals.install(subscription) do
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
	end
end

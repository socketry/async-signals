# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "open3"
require "rbconfig"

describe "Async::Signals::Graceful" do
	def ruby(script)
		::Open3.capture3(::RbConfig.ruby, "-Ilib", "-e", script)
	end
	
	def expect_success(script)
		stdout, stderr, status = ruby(script)
		
		expect(status).to be(:success?)
		expect(stderr).to be == ""
		
		stdout
	end
	
	it "installs graceful SIGINT handling" do
		stdout = expect_success(<<~RUBY)
			require "async/signals/graceful"
			
			begin
				::Thread.handle_interrupt(::Interrupt => :never) do
					::Process.kill(:INT, ::Process.pid)
					puts "inner"
				end
				
				sleep 1
			rescue ::Interrupt
				puts "outer"
			end
		RUBY
		
		expect(stdout).to be == "inner\nouter\n"
	end
	
	it "installs graceful SIGTERM handling" do
		stdout = expect_success(<<~RUBY)
			require "async/signals/graceful"
			
			begin
				::Thread.handle_interrupt(::Interrupt => :never) do
					::Process.kill(:TERM, ::Process.pid)
					puts "inner"
				end
				
				sleep 1
			rescue ::Interrupt
				puts "outer"
			end
		RUBY
		
		expect(stdout).to be == "inner\nouter\n"
	end
	
	it "preserves existing SIGINT handlers" do
		stdout = expect_success(<<~RUBY)
			events = ::Thread::Queue.new
			
			::Signal.trap(:INT) do
				events << "handled"
			end
			
			require "async/signals/graceful"
			
			::Process.kill(:INT, ::Process.pid)
			
			puts events.pop(timeout: 1)
		RUBY
		
		expect(stdout).to be == "handled\n"
	end
	
	it "preserves existing SIGTERM handlers" do
		stdout = expect_success(<<~RUBY)
			events = ::Thread::Queue.new
			
			::Signal.trap(:TERM) do
				events << "handled"
			end
			
			require "async/signals/graceful"
			
			::Process.kill(:TERM, ::Process.pid)
			
			puts events.pop(timeout: 1)
		RUBY
		
		expect(stdout).to be == "handled\n"
	end
end

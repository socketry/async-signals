# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/reset"

describe Async::Signals::Reset do
	with ".trap" do
		it "stores reset traps" do
			handler = proc{}
			
			begin
				subject.trap(:USR1, &handler)
				
				expect(subject.to_h).to have_keys(
					"USR1" => be == handler
				)
			ensure
				subject.clear
			end
		end
		
		it "stores nil for ignored reset traps" do
			begin
				subject.trap(:USR1)
				
				expect(subject.to_h).to have_keys(
					"USR1" => be_nil
				)
			ensure
				subject.clear
			end
		end
	end
	
	with ".clear" do
		it "removes all reset traps" do
			subject.trap(:USR1){}
			subject.clear
			
			expect(subject.to_h).to be == {}
		end
	end
end

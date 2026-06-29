# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "async/signals/reset"

describe "Async::Signals::Graceful" do
	it "registers graceful reset traps" do
		begin
			Async::Signals::Reset.clear
			
			load File.expand_path("../../../lib/async/signals/graceful.rb", __dir__)
			
			traps = Async::Signals::Reset.to_h
			
			expect(traps["INT"]).to be_a(Proc)
			expect(traps["TERM"]).to be_a(Proc)
			
			expect{traps["INT"].call}.to raise_exception(Interrupt)
			expect{traps["TERM"].call}.to raise_exception(Interrupt)
		ensure
			Async::Signals::Reset.clear
		end
	end
end

# frozen_string_literal: true

require_relative "lib/async/signals/version"

Gem::Specification.new do |spec|
	spec.name = "async-signals"
	spec.version = Async::Signals::VERSION
	
	spec.summary = "Composable process signal handling for Ruby."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/async-signals"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/async-signals/",
		"source_code_uri" => "https://github.com/socketry/async-signals.git",
	}
	
	spec.files = Dir.glob(["{context,guides,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
end

# frozen_string_literal: true
require_relative 'lib/asset_db/version'

Gem::Specification.new do |spec|
	spec.name          = 'asset_db'
	spec.version       = AssetDB::VERSION
	spec.authors       = ['Convincible Media']
	spec.email         = ['development@convincible.media']

	spec.summary       = "Lightweight asset dependency database for Ruby"
	spec.description   = "Provides a structured way to define, organise, and resolve assets (CSS, JS, etc.) and their interdependencies across packages and groups."
	spec.homepage      = 'https://github.com/ConvincibleMedia/ruby-gem-assetdb'
	spec.license       = 'MIT'

	spec.required_ruby_version = '>= 2.4'

	# Files to include in the gem
	spec.files = Dir.chdir(__dir__) do
		`git ls-files -z`.split("\x0").grep(%r{\A(?:lib|README\.md|LICENSE|asset_db\.gemspec)\z})
	end

	# No runtime dependencies
	# Development dependencies
	spec.add_development_dependency 'bundler', '~> 2.0'
	spec.add_development_dependency 'rake',    '~> 13.0'
	spec.add_development_dependency 'rspec',   '~> 3.0'
end

# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'
require 'rspec'
require_relative '../lib/asset_db'   # adjust if gem namespace differs

RSpec.configure do |config|
	config.color     = true
	config.formatter = :documentation
	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end

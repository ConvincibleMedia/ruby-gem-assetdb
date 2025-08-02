# frozen_string_literal: true

require 'set'
require_relative 'asset_db/version'
require_relative 'asset_db/errors'
require_relative 'asset_db/asset'
require_relative 'asset_db/package'
require_relative 'asset_db/group'
require_relative 'asset_db/resolver'
require_relative 'asset_db/database'

module AssetDB
	# DSL entry-point – e.g.:
	# db = AssetDB.build(asset_types: %i[css js]) do |d|
	#   d.group 'features' do |g|
	#     g.package 'dropdown' do |p|
	#       p.asset :css, 'drop.css'
	#     end
	#   end
	# end
	def self.build(asset_types: nil, base_path: nil, &block)  # arg renamed for consistency
		db = Database.new(asset_types: asset_types, base_path: base_path)
		yield db if block
		db
	end

	# Configuration-driven construction.
	# Pass a Hash shaped like the example in README and receive a ready Database.
	def self.load(config)
		Database.from_config(config)
	end
end

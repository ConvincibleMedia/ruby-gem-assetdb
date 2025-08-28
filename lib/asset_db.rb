# frozen_string_literal: true

require 'set'

# version must come first so errors, etc. have a version constant available
require_relative 'asset_db/version'
require_relative 'asset_db/errors'
require_relative 'asset_db/asset'
require_relative 'asset_db/group'
require_relative 'asset_db/package'
require_relative 'asset_db/resolver'
require_relative 'asset_db/database'

module AssetDB
	# DSL entry point, e.g.
	#
	#   db = AssetDB.build(types: %i[css js], basepath: '/assets/:type/:group/:package') do |d|
	#     # ...
	#   end
	def self.build(types: nil, basepath: nil, &block)
		db = Database.new(asset_types: types, basepath: basepath)
		yield db if block
		db
	end

	# Configuration-driven constructor:
	#
	#   db = AssetDB.load(config_hash)
	#
	def self.load(config)
		Database.from_config(config)
	end
end

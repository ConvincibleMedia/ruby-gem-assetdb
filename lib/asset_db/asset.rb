# frozen_string_literal: true

require 'uri'

module AssetDB
	class Asset
		attr_reader :type, :id, :url, :metadata, :group, :package

		def initialize(type:, group:, package:, url:, metadata: nil, id: url)
			@type     = type.to_sym
			@url      = url.to_s.freeze
			@metadata = metadata
			@id       = id.to_s.freeze
			@package  = package
			@group    = group
		end

		def ==(other)
			other.is_a?(Asset) && other.id == id
		end
		alias eql? ==

		def hash
			id.hash
		end

		def protocol_url?
			@protocol ||= url =~ /\A[A-Za-z][A-Za-z0-9+\-.]*:\/\//
		end
	end
end

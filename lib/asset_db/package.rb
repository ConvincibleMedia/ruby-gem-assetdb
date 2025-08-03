# frozen_string_literal: true

module AssetDB
	class Package
		FOLDER_DEFAULT = :__default

		attr_reader :id, :group

		def initialize(group, id, folder: FOLDER_DEFAULT)
			@group        = group
			database.validate_identifier!(id)
			@id           = id.to_s
			@folder       = folder.equal?(FOLDER_DEFAULT) ? FOLDER_DEFAULT : folder
			@assets       = Hash.new { |h, k| h[k] = [] }  # {type ⇒ [Asset]}
			@dependencies = []                             # [[group_id, package_id]]
			@cache        = {}                             # {type|:all ⇒ …}
		end

		def asset(type, url, metadata = nil, id: url)
			type = type.to_sym
			check_type!(type)
			@assets[type] << Asset.new(type: type, url: url, group: group, package: self, metadata: metadata, id: id)
			invalidate_cache
			self
		end

		def depends_on(pkg_id, group_id: group.id)
			@dependencies << [group_id.to_s, pkg_id.to_s]
			invalidate_cache
			self
		end

		def resolved_assets(type = nil)
			key = type ? type.to_sym : :all
			@cache[key] ||= database.resolver.resolve(self, type: type&.to_sym)
		end

		def +(other)
			database.unify(self, other)
		end

		def folder_segment
			return id            if @folder.equal?(FOLDER_DEFAULT)
			return nil           if !@folder || @folder == '' || @folder == false
			@folder.to_s
		end

		def assets
			@assets
		end
		def dependencies
			@dependencies
		end
		def key?
			"#{group.id}/#{id}".freeze
		end
		def database
			group.database
		end

		private

		def invalidate_cache
			@cache.clear
		end
		def check_type!(t)
			database.asset_types.include?(t) or raise ArgumentError, "Unknown type #{t}"
		end

	end
end

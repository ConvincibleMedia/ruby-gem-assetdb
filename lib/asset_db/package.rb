# frozen_string_literal: true

module AssetDB
	class Package
		FOLDER_DEFAULT = :__default

		attr_reader :id, :group

		def initialize(group, id, folder: FOLDER_DEFAULT)
			validate_identifier!(id)
			@group        = group
			@id           = id.to_s
			@folder       = folder.equal?(FOLDER_DEFAULT) ? FOLDER_DEFAULT : folder
			@assets       = Hash.new { |h, k| h[k] = [] }  # {type ⇒ [Asset]}
			@dependencies = []                             # [[group_id, package_id]]
			@cache        = {}                             # {type|:all ⇒ …}
		end

		def asset(type, url, metadata = nil, id: url)
			type = type.to_sym
			check_type!(type)
			@assets[type] << Asset.new(type, url, metadata, id: id)
			invalidate_cache
			self
		end

		def depends_on(pkg_id, in: group.id)
			@dependencies << [in.to_s, pkg_id.to_s]
			invalidate_cache
			self
		end

		def resolved_assets(type = nil)
			key = type ? type.to_sym : :all
			@cache[key] ||= group.database.resolver.resolve(self, type: type&.to_sym)
		end

		def +(other)
			Resolver::PackageCollection.new(group.database, [self, other].flatten)
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

		private

		def invalidate_cache
      @cache.clear
    end
		def check_type!(t)
      group.database.asset_types.include?(t) or raise ArgumentError, "Unknown type #{t}"
    end

		def validate_identifier!(name)
			raise Errors::InvalidIdentifierError, "‘/’ forbidden in identifier #{name.inspect}" if name.to_s.include?('/')
		end
	end
end

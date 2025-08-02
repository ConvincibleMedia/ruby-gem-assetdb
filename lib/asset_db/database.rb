# frozen_string_literal: true

require 'uri'

module AssetDB
	class Database
		CONFIG_RESERVED = %w[types basepath folders].freeze

		attr_reader :asset_types, :base_path, :groups, :resolver

		def initialize(asset_types: nil, base_path: nil)
			@asset_types = (asset_types&.map(&:to_sym) || %i[css js]).freeze
			@base_path   = (base_path || '').dup
			@groups      = {} # {id ⇒ Group}
			@resolver    = Resolver.new(self)
		end

		# ----------------  DSL helpers ----------------
		G_FOLDER_DEFAULT = Group::FOLDER_DEFAULT
		def group(id, folder: G_FOLDER_DEFAULT, &block)
			g = (@groups[id.to_s] ||= Group.new(self, id, folder: folder))
			yield g if block
			g
		end

		def groups
      @groups.values
    end
		def asset_types
      @asset_types
    end

		# Strict fetch for resolver
		def group!(id)
			@groups[id.to_s] or raise Errors::UnknownGroupError, id
		end

		def package!(g_id, p_id)
			group!(g_id).instance_variable_get(:@packages_hash)[p_id.to_s] or
				raise Errors::UnknownPackageError, "#{g_id}/#{p_id}"
		end

		# ---------------  URL expansion ---------------
		def build_url(asset, group, package)
			return asset.url if asset.protocol_url?
			return ensure_root_slash(asset.url) if asset.url.start_with?('/')

			path = @base_path.dup
			unless path.empty?
				path.gsub!(':type',    asset.type.to_s)
				path.gsub!(':group',   group.folder_segment.to_s)
				path.gsub!(':package', package.folder_segment.to_s)
			end

			ensure_root_slash(File.join(path, asset.url))
		end

		def ensure_root_slash(pth)
			('/' + pth.gsub(%r{^/+}, '')).gsub(%r{/{2,}}, '/')
		end

		# ---------------  Config loader ---------------
		def self.from_config(cfg)
			cfg = cfg.transform_keys(&:to_s)
			db  = new(asset_types: cfg['types'], base_path: cfg['basepath'])

			folders_map = (cfg['folders'] || {}).transform_keys(&:to_s)

			cfg.each do |g_id, g_spec|
				next if CONFIG_RESERVED.include?(g_id)

				raise Errors::InvalidIdentifierError, "group name ‘#{g_id}’ conflicts with asset type" \
					if db.asset_types.include?(g_id.to_sym)

				group_folder = folders_map[g_id]
				g            = db.group(g_id, folder: group_folder)
				gid          = g_id.to_s

				g_spec.each do |p_id, p_spec|
					pkg_folder = folders_map["#{gid}/#{p_id}"]
					pkg        = g.package(p_id, folder: pkg_folder)

					p_spec.each do |k, v|
						key = k.to_s
						if db.asset_types.include?(key.to_sym) # assets
							Array(v).each { |url| pkg.asset(key, url) }
						else                                   # dependencies
							Array(v).each { |target_pkg| pkg.depends_on(target_pkg, in: key) }
						end
					end
				end
			end
			db
		end
	end
end

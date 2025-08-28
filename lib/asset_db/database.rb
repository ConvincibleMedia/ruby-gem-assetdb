# frozen_string_literal: true

require 'uri'

module AssetDB
	class Database
		CONFIG_RESERVED = %w[types basepath folders].freeze

		attr_reader :asset_types, :basepath, :groups, :resolver
		attr_accessor :separator

		def initialize(asset_types: nil, basepath: nil)
			@asset_types = (asset_types&.map(&:to_sym) || %i[css js]).freeze
			@basepath   = (basepath || '').dup
			@separator   = nil
			@groups      = {} # {id ⇒ Group}
			@resolver    = Resolver.new(self)
		end

		# DSL helpers
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
		def build_url(asset)
			return asset.url if asset.protocol_url?
			return ensure_root_slash(asset.url) if asset.url.start_with?('/')

			group  = asset.group
			package = asset.package
			path = @basepath.dup
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
			db  = new(asset_types: cfg['types'], basepath: cfg['basepath'])

			folders_map = (cfg['folders'] || {}).transform_keys(&:to_s).dup
			if sep = folders_map.delete('separator')
				db.separator = sep.to_s
			end

			cfg.each do |g_id, g_spec|
				next if CONFIG_RESERVED.include?(g_id)
			
				raise Errors::InvalidIdentifierError,
							"group name ‘#{g_id}’ conflicts with asset type" \
							if db.asset_types.include?(g_id.to_sym)
			
				# ----------  GROUP ---------- #
				if (folders_map.key? g_id)
					g = db.group(g_id, folder: folders_map[g_id])           # explicit override (can be nil/false/empty)
				else
					g = db.group(g_id)                                      # default ⇒ id
				end
				gid = g_id.to_s
			
				# ----------  PACKAGES ---------- #
				g_spec.each do |p_id, p_spec|
					p_key = "#{gid}#{db.separator}#{p_id}"                                # composite key for folder overrides
			
					if (folders_map.key? p_key)
						pkg = g.package(p_id, folder: folders_map[p_key])   # explicit override
					else
						pkg = g.package(p_id)                               # default ⇒ id
					end
			
					p_spec.each do |k, v|
						key = k.to_s
						if db.asset_types.include?(key.to_sym)              # ASSETS
							Array(v).each { |url| pkg.asset(key, url == true ? p_id + '.' + key : url) }
						else                                                # DEPENDENCIES
							Array(v).each { |target_pkg| pkg.depends_on(target_pkg, group_id: key) }
						end
					end
				end
			end
			
			db
		end

		# Unify any number (≥2) of Package or PackageCollection into one collection
		def unify(*items)
			# Simple returns
			if items.empty?
				return nil
			elsif items.size == 1
				return Resolver::PackageCollection.new(self, items.first)
			end

			# Combine packages
			merged = items.flat_map do |i|
			case i
				when Resolver::PackageCollection
					i.instance_variable_get(:@packages)
				when Package
					[i]
				else
					raise ArgumentError, "Cannot unify #{i.inspect}"
				end
			end
			Resolver::PackageCollection.new(self, merged)
		end

		def validate_identifier!(name)
			if separator && name.to_s.include?(separator)
				raise Errors::InvalidIdentifierError, "'#{separator}' forbidden in identifier #{name.inspect}"
			end
		end

	end
end

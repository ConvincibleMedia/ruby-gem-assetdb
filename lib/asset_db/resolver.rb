# frozen_string_literal: true

require 'set'

module AssetDB
	class Resolver
		def initialize(database)
			@database = database
			@memo     = {} # {pkg_key ⇒ {type|:all ⇒ result}}
			@mutex    = Mutex.new
		end

		def resolve(pkg, type: nil)
			type_key = type ? type.to_sym : :all
			@mutex.synchronize { (@memo[pkg.key?] ||= {})[type_key] ||= (type ? dfs_type(pkg, type_key) : dfs_all(pkg)) }
		end

		# --------------------------------------------------
		#   private helpers
		# --------------------------------------------------
		private

		def dfs_type(pkg, type, visiting = Set.new, stack = [])
			return @memo.dig(pkg.key?, type) if @memo.dig(pkg.key?, type)

			raise Errors::CycleError.new(stack + [pkg]) if visiting.include?(pkg.key?)
			visiting.add(pkg.key?); stack.push(pkg)

			ordered     = []
			seen_ids    = Set.new

			pkg.dependencies.each do |(g_id, p_id)|
				dep_pkg = @database.package!(g_id, p_id)
				dfs_type(dep_pkg, type, visiting, stack).each do |asset|
					next if seen_ids.include?(asset.id)
					seen_ids << asset.id
					ordered   << asset
				end
			end

			pkg.assets[type].each do |asset|
				next if seen_ids.include?(asset.id)
				seen_ids << asset.id
				ordered   << asset
			end

			stack.pop; visiting.delete(pkg.key?)
			ordered.freeze
		end

		def dfs_all(pkg, visiting = Set.new, stack = [])
			return @memo.dig(pkg.key?, :all) if @memo.dig(pkg.key?, :all)

			raise Errors::CycleError.new(stack + [pkg]) if visiting.include?(pkg.key?)
			visiting.add(pkg.key?); stack.push(pkg)

			result     = Hash.new { |h, k| h[k] = [] }
			seen       = Hash.new { |h, k| h[k] = Set.new }

			pkg.dependencies.each do |(g_id, p_id)|
				dep_pkg = @database.package!(g_id, p_id)
				dfs_all(dep_pkg, visiting, stack).each do |t, assets|
					assets.each do |asset|
						next if seen[t].include?(asset.id)
						seen[t]   << asset.id
						result[t] << asset
					end
				end
			end

			pkg.assets.each do |t, assets|
				assets.each do |asset|
					next if seen[t].include?(asset.id)
					seen[t]   << asset.id
					result[t] << asset
				end
			end

			stack.pop; visiting.delete(pkg.key?)
			result.transform_values!(&:freeze).freeze
		end

		# --------------------------------------------------
		#   lightweight immutable union façade
		# --------------------------------------------------
		class PackageCollection
			include Enumerable

			def initialize(database, pkgs)
				@database = database
				@packages = pkgs.map(&:itself).uniq
				@cache    = {} # {[type, key] ⇒ [Asset]}
			end

			def +(other)
				@database.unify(self, other)
			end

			def each_asset(type = nil, &block)
				return @database.asset_types.each { |t| each_asset(t, &block) } if type.nil?

				type = type.to_sym
				key  = [type, @packages.map(&:key?).sort].hash
				@cache[key] ||= begin
					seen = Set.new
					arr  = []
					@packages.each do |pkg|
						pkg.resolved_assets(type).each do |asset|
							next if seen.include?(asset.id)
							seen << asset.id
							arr  << asset
						end
					end
					arr.freeze
				end
				block ? @cache[key].each(&block) : @cache[key]
			end

			def each
				return to_enum(:each) unless block_given?

				seen = Set.new
				@database.asset_types.each do |type|
					each_asset(type).each do |asset|
						next if seen.include?(asset.id)   # de-dupe across types just in case
						seen << asset.id
						yield asset
					end
				end
				self
			end

		end
	end
end

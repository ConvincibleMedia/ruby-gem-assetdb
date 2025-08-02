# frozen_string_literal: true

module AssetDB
	class Group
		FOLDER_DEFAULT = :__default

		attr_reader :database, :id

		def initialize(database, id, folder: FOLDER_DEFAULT)
			validate_identifier!(id)
			@database      = database
			@id            = id.to_s
			@folder        = folder.equal?(FOLDER_DEFAULT) ? FOLDER_DEFAULT : folder
			@packages_hash = {} # {id ⇒ Package}
		end

		# DSL – fetch or create.
		def package(id, folder: FOLDER_DEFAULT, &block)
			pkg = (@packages_hash[id.to_s] ||= Package.new(self, id, folder: folder))
			yield pkg if block
			pkg
		end

		def packages
			@packages_hash.values
		end
		def package_ids
			@packages_hash.keys
		end
		def folder_spec
			@folder
		end

		def folder_segment
			return id            if @folder.equal?(FOLDER_DEFAULT)
			return nil           if !@folder || @folder == '' || @folder == false
			@folder.to_s
		end

		private

		def validate_identifier!(name)
			raise Errors::InvalidIdentifierError, "‘/’ forbidden in identifier #{name.inspect}" if name.to_s.include?('/')
		end
	end
end

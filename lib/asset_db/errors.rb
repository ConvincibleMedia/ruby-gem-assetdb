# frozen_string_literal: true

module AssetDB
	module Errors
		class AssetDBError          < StandardError; end
		class UnknownGroupError     < AssetDBError; end
		class UnknownPackageError   < AssetDBError; end
		class CycleError            < AssetDBError
			attr_reader :cycle
			def initialize(cycle)
				@cycle = cycle
				super("Dependency cycle detected: " \
				      cycle.map { |p| "#{p.group.id}:#{p.id}" }.join(' → '))
			end
		end
		class InvalidIdentifierError < AssetDBError; end
	end
end

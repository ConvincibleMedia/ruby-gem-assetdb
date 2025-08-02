# frozen_string_literal: true
require_relative 'spec_helper'

RSpec.describe AssetDB::Resolver::PackageCollection do
	let(:db)    { AssetDB::Database.new }
	let(:a)     { db.group('g').package('a').asset(:css, 'a.css') }
	let(:b)     { db.group('g').package('b').asset(:js,  'b.js') }
	let(:c)     { db.group('g').package('c').asset(:css, 'c.css').depends_on('a', group_id: 'g') }

  before { a }
  
	it 'enumerates all assets when type omitted' do
		union = a + b + c
		expect(union.to_a.map(&:id)).to match_array %w[a.css c.css b.js]
	end

	it 'deduplicates across multiple packages' do
		union = a + c
		expect(union.each_asset(:css).map(&:id)).to eq %w[a.css c.css]
	end

	it 'preserves deterministic order (deps first)' do
		expect(c.resolved_assets(:css).map(&:id)).to eq %w[a.css c.css]
	end
end

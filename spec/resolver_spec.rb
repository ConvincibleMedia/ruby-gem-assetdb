# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe AssetDB::Resolver do
	let(:db)    { AssetDB::Database.new }
	let(:core)  { db.group('core').package('base').asset(:css, 'base.css') }
	let(:feat)  { db.group('features').package('dropdown').asset(:css, 'drop.css').depends_on('base', group_id: 'core') }

	before { core; feat } # build graph

	it 'resolves transitive dependencies in order' do
		expect(feat.resolved_assets(:css).map(&:id)).to eq %w[base.css drop.css]
	end

	it 'deduplicates identical assets across deps' do
		core2 = db.group('extras').package('core2').asset(:css, 'base.css')
		feat.depends_on('core2', group_id: 'extras')
		expect(feat.resolved_assets(:css).map(&:id)).to eq %w[base.css drop.css]
	end

	it 'returns hash when type is nil' do
		expect(feat.resolved_assets).to be_a(Hash)
		expect(feat.resolved_assets.keys).to include(:css)
	end

	it 'detects cycles' do
		core.depends_on('dropdown', group_id: 'features')
		expect { feat.resolved_assets(:css) }.to raise_error(AssetDB::Errors::CycleError)
	end

	describe 'PackageCollection union' do
		let(:pkg_b) { db.group('extras').package('utils').asset(:css, 'util.css') }

		it 'unions packages without duplicates' do
			union = feat + pkg_b
			expect(union.each_asset(:css).map(&:id)).to eq %w[base.css drop.css util.css]
		end

		it 'is chainable' do
			union = feat + pkg_b + core
			expect(union.each_asset(:css).map(&:id)).to eq %w[base.css drop.css util.css]
		end
	end
end

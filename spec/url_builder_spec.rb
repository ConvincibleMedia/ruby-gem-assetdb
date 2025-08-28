# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'URL builder' do
	let(:basepath) { '/assets/:type/:group/:package' }
	let(:db)       { AssetDB::Database.new(basepath: basepath) }

	context 'protocol URLs' do
		it 'returns unchanged when protocol present' do
			pkg   = db.group('g').package('p').asset(:css, 'https://cdn/a.css')
			asset = pkg.assets[:css].first
			expect(db.build_url(asset)).to eq 'https://cdn/a.css'
		end
	end

	context 'absolute root URLs' do
		it 'keeps single leading slash & ignores basepath' do
			pkg   = db.group('g').package('p').asset(:css, '/img/logo.png')
			asset = pkg.assets[:css].first
			expect(db.build_url(asset)).to eq '/img/logo.png'
		end
	end

	context 'relative URLs with empty basepath' do
		it 'prefixes a slash even when basepath is empty' do
			db2   = AssetDB::Database.new
			pkg   = db2.group('g').package('p').asset(:css, 'file.css')
			asset = pkg.assets[:css].first
			expect(db2.build_url(asset)).to eq '/file.css'
		end
	end

	context 'placeholder substitution' do
		it 'includes folders by default' do
			pkg   = db.group('features').package('dropdown').asset(:css, 'drop.css')
			asset = pkg.assets[:css].first
			expect(db.build_url(asset))
				.to eq '/assets/css/features/dropdown/drop.css'
		end

		it 'collapses segments when folder is nil' do
			db.group('features', folder: nil)
			pkg = db.group('features').package('dropdown', folder: nil)
			      .asset(:css, 'drop.css')
			asset = pkg.assets[:css].first
			expect(db.build_url(asset))
				.to eq '/assets/css/drop.css'
		end

		it 'uses custom folder overrides' do
			pkg = db.group('core', folder: 'lib')
			        .package('base', folder: 'foundation')
			        .asset(:css, 'base.css')
			asset = pkg.assets[:css].first
			expect(db.build_url(asset))
				.to eq '/assets/css/lib/foundation/base.css'
		end
	end
end

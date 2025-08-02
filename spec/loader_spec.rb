# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Configuration loader' do
	let(:cfg) do
		{
			types:     %w[css js],
			basepath:  '/assets/:type/in_:group/:package_package',
			folders:   { 'core' => 'common', 'features/dropdown' => nil },
			core: {
				base: { css: 'base.css' }
			},
			features: {
				dropdown: {
					css: 'drop.css',
					core: 'base'
				}
			},
			group: {
				package: {
					css: 'simple.css'
				}
			}
		}
	end

	subject(:db) { AssetDB.load(cfg) }

	it 'constructs asset URLs according to basepath' do
		pkg   = db.group('group').package('package')
		asset = pkg.resolved_assets(:css).first
		url   = db.build_url(asset)
		expect(url).to eq '/assets/css/in_group/package_package/simple.css' # group folder collapsed, package folder collapsed
	end

	it 'parses dependency shorthand' do
		expect(
			db.group('features').package('dropdown').resolved_assets(:css).map(&:id)
		).to eq %w[base.css drop.css]
	end

	it 'treats type & group names case-insensitively between symbol / string' do
		pkg = db.group(:features).package(:dropdown)
		expect(pkg.resolved_assets(:css).size).to eq 2
	end

	it 'rejects group name equal to asset type' do
		bad = cfg.merge('css' => {})
		expect { AssetDB.load(bad) }.to raise_error(AssetDB::Errors::InvalidIdentifierError)
	end
end

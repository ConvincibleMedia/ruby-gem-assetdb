# frozen_string_literal: true

RSpec.describe 'Configuration loader' do
	let(:cfg) do
		{
			types:     %w[css js],
			basepath:  '/assets/:type/:group/:package',
			folders:   { 'core' => 'common', 'features/dropdown' => nil },
			core: {
				base: { css: 'base.css' }
			},
			features: {
				dropdown: {
					css: 'drop.css',
					core: 'base'
				}
			}
		}
	end

	subject(:db) { AssetDB.load(cfg) }

	it 'honours custom folders in URL resolution' do
		pkg   = db.group('features').package('dropdown')
		first = pkg.resolved_assets(:css).first
		url   = db.build_url(first, pkg.group, pkg)
		expect(url).to eq '/assets/css/dropdown/base.css' # group folder collapsed, package folder collapsed
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

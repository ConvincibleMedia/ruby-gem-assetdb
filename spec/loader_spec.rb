# frozen_string_literal: true

RSpec.describe 'Configuration loader' do
	let(:cfg) do
		{
			types:     %w[css js],
			basepath:  '/assets/:type/:group/:package',
			folders:   { core: 'common', :'features/dropdown' => nil },
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
		expect(url).to eq '/assets/css/group/package/simple.css' # group folder collapsed, package folder collapsed
	end

	it 'honours custom folders in URL resolution' do
		pkg    = db.group('features').package('dropdown')
		assets = pkg.resolved_assets(:css)
		first  = assets.first
		second = assets.last
		url1   = db.build_url(first)
		url2   = db.build_url(second)
		expect(url1).to eq '/assets/css/common/base/base.css' # group folder collapsed, package folder collapsed
		expect(url2).to eq '/assets/css/features/drop.css' # group folder collapsed, package folder collapsed
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

# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe 'Folder override precedence' do
	let(:db) do
		AssetDB.load(
			types:     %w[css],
			basepath:  '/a/:group/:package',      # keep short for assertions
			folders:   {
				'core'            => 'lib',
				'core/base'       => nil,          # collapse package
				'features'        => nil,
				'features/upper'  => 'caps'
			},
			core: {
				base: { css: 'b.css' }
			},
			features: {
				upper: { css: 'u.css' }
			}
		)
	end

	it 'package folder override supersedes group override' do
		pkg   = db.group('core').package('base')
		asset = pkg.assets[:css].first
		expect(db.build_url(asset)).to eq '/a/lib/b.css'
	end

	it 'group override still applies to other packages' do
		pkg   = db.group('core').package('extra').asset(:css, 'e.css')
		asset = pkg.assets[:css].first
		expect(db.build_url(asset)).to eq '/a/lib/extra/e.css'
	end

	it 'collapsed group folder drops segment' do
		pkg   = db.group('features').package('upper')
		asset = pkg.assets[:css].first
		expect(db.build_url(asset)).to eq '/a/caps/u.css'
	end
end

# frozen_string_literal: true

RSpec.describe AssetDB::Database do
	let(:db) { described_class.new }

	it 'defaults to css/js asset types' do
		expect(db.asset_types).to eq %i[css js]
	end

	it 'can set custom types' do
		custom = described_class.new(asset_types: %w[img font])
		expect(custom.asset_types).to eq %i[img font]
	end

	it 'enumerates groups & packages' do
		a = db.group('g1').package('p1')
		b = db.group('g2').package('p2')
		expect(db.groups.map(&:id)).to contain_exactly('g1', 'g2')
		expect(db.group('g1').packages.map(&:id)).to contain_exactly('p1')
	end

	it 'rejects "/" in identifiers' do
		expect { db.group('bad/name') }.to raise_error(AssetDB::Errors::InvalidIdentifierError)
		expect { db.group('g').package('bad/name') }.to raise_error(AssetDB::Errors::InvalidIdentifierError)
	end
end

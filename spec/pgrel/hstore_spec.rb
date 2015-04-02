require 'spec_helper'

describe Hstore do
  before do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table('hstores') do |t|
        t.hstore 'tags', default: {}, null: false
        t.string 'name'
      end
    end

    Hstore.reset_column_information
  end

  after do
    @connection.drop_table 'hstores', if_exists: true
  end

  let!(:setup) do
    Hstore.create!(name: 'a', tags: { a: 1, b: 2, f: true, d: 'a', g: 'b' })
    Hstore.create!(name: 'b', tags: { a: 2, d: 'b', g: 'e' })
    Hstore.create!(name: 'c', tags: { f: true, d: 'b' })
    Hstore.create!(name: 'd', tags: { f: false })
    Hstore.create!(name: 'e', tags: { a: 2, c: 'x', d: 'c', g: 'c' })
  end

  context '#where' do
    it 'simple values' do
      expect(Hstore.where.store(:tags, a: 1, b: 2).first.name).to eq 'a'
      expect(Hstore.where.store(:tags, a: 2, c: 'x').first.name).to eq 'e'
      expect(Hstore.where.store(:tags, f: false).first.name).to eq 'd'
    end

    it 'arrays' do
      expect(Hstore.where.store(:tags, a: [1, 2, 3]).size).to eq 3
    end

    it 'many arrays' do
      expect(
        Hstore.where.store(
          :tags,
          a: [1, 2, 3],
          c: %w(x y z),
          d: %w(a c),
          g: %w(b c)
          ).size
        ).to eq 1
      expect(
        Hstore.where.store(
          :tags,
          a: [1, 2, 3],
          d: %w(a c),
          g: %w(b c)
          ).size
        ).to eq 2
    end
  end

  it '#key' do
    records = Hstore.where.store(:tags).key(:a)
    expect(records.size).to eq 3

    records = Hstore.where.store(:tags).key(:b)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'a'
  end

  it '#keys' do
    records = Hstore.where.store(:tags).keys('a', 'f')
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'a'

    records = Hstore.where.store(:tags).keys([:a, :c])
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'e'
  end

  it '#any' do
    records = Hstore.where.store(:tags).any('b', 'f')
    expect(records.size).to eq 3

    records = Hstore.where.store(:tags).any([:c, :b])
    expect(records.size).to eq 2
  end

  it '#contains' do
    records = Hstore.where.store(:tags).contains(f: true)
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).contains(a: 2, c: 'x')
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'e'
  end

  it '#contained' do
    records = Hstore.where.store(:tags).contained(
      a: 2,
      b: 2,
      f: true,
      d: 'b',
      g: 'e'
    )
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).contained(c: 'x', f: false)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'd'
  end
end

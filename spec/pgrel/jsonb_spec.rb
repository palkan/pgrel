require 'spec_helper'

describe Jsonb do
  before do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table('jsonbs') do |t|
        t.jsonb 'tags', default: {}, null: false
        t.string 'name'
      end
    end

    Jsonb.reset_column_information
  end

  after do
    @connection.drop_table 'jsonbs', if_exists: true
  end

  let!(:setup) do
    Jsonb.create!(name: 'a')
    Jsonb.create!(name: 'b', tags: { a: 1, d: { e: 2 } })
    Jsonb.create!(name: 'c', tags: { a: 2, b: %w(c d) })
    Jsonb.create!(name: 'd', tags: { a: 1, b: { c: 'd', e: true } })
    Jsonb.create!(name: 'e', tags: { b: 2, c: 'e' })
    Jsonb.create!(name: 'f', tags: { d: { e: 1, f: { h: { k: 'a', s: 2 } } } })
  end

  context '#where' do
    it 'simple values' do
      expect(Jsonb.where.store(:tags, b: 2, c: 'e').first.name).to eq 'e'
    end

    it 'nested values' do
      expect(
        Jsonb.where.store(
          :tags,
          a: 1,
          b: { c: 'd', e: true }
        ).first.name).to eq 'd'
    end

    it 'arrays' do
      expect(Jsonb.where.store(:tags, a: [1, 2, 3]).size).to eq 3
    end
  end

  context '#path' do
    it 'pass object' do
      expect(Jsonb.where.store(:tags).path(b: { c: 'd' }).first.name).to eq 'd'

      expect(
        Jsonb.where.store(:tags).path(
          d: { f:  { h: { s: 2 } } }
        ).first.name
      ).to eq 'f'
    end

    it 'pass array' do
      expect(Jsonb.where.store(:tags).path(:b, :c, 'd').first.name).to eq 'd'
    end

    it 'match object' do
      expect(
        Jsonb.where.store(:tags).path(:d, :f, :h, k: 'a', s: 2).first.name
      ).to eq 'f'
    end

    it 'match array (as IN)' do
      expect(Jsonb.where.store(:tags).path(:d, :e, [1, 2]).size).to eq 2
      expect(Jsonb.where.store(:tags).path(d: { e: [1, 2] }).size).to eq 2
    end
  end

  it '#key' do
    records = Jsonb.where.store(:tags).key(:a)
    expect(records.size).to eq 3

    records = Jsonb.where.store(:tags).key(:c)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'e'
  end

  it '#keys' do
    records = Jsonb.where.store(:tags).keys('a', 'b')
    expect(records.size).to eq 2

    records = Jsonb.where.store(:tags).keys([:b, :c])
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'e'
  end

  it '#any' do
    records = Jsonb.where.store(:tags).any('a', 'b')
    expect(records.size).to eq 4

    records = Jsonb.where.store(:tags).any([:c, :b])
    expect(records.size).to eq 3
  end

  it '#contains' do
    records = Jsonb.where.store(:tags).contains(a: 1)
    expect(records.size).to eq 2

    records = Jsonb.where.store(:tags).contains(a: 1, b: { c: 'd' })
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'd'
  end

  it '#contained' do
    records = Jsonb.where.store(:tags).contained(
      a: 2,
      b: 2,
      f: true,
      c: 'e',
      g: 'e'
    )
    expect(records.size).to eq 2

    records =
      Jsonb
      .where.store(:tags).key(:a)
      .where.store(:tags).contained(a: 2, b: %w(a b c d))

    expect(records.size).to eq 1
    expect(records.first.name).to eq 'c'
  end
end

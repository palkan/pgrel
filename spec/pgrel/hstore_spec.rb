require 'spec_helper'

describe Hstore do
  let!(:setup) do
    Hstore.create!(name: 'a', tags: { a: 1, b: 2, f: true })
    Hstore.create!(name: 'b', tags: { a: 2 })
    Hstore.create!(name: 'c', tags: { f: true })
    Hstore.create!(name: 'd', tags: { f: false })
    Hstore.create!(name: 'e', tags: { a: 2, c: 'x' })
  end

  after(:all) do
    Hstore.delete_all
  end

  it '#store with kwargs' do
    expect(Hstore.where.store(:tags, a: 1, b: 2).first.name).to eq 'a'
    expect(Hstore.where.store(:tags, a: 2, c: 'x').first.name).to eq 'e'
    expect(Hstore.where.store(:tags, f: false).first.name).to eq 'd'
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

    records = Hstore.where.store(:tags).keys(:a, :c)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'e'
  end

  it '#any' do
    records = Hstore.where.store(:tags).any('b', 'f')
    expect(records.size).to eq 3

    records = Hstore.where.store(:tags).any(:c, :b)
    expect(records.size).to eq 2
  end

  it '#contain' do
    records = Hstore.where.store(:tags).contain(f: true)
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).contain(a: 2, c: 'x')
    expect(records.size).to eq
    expect(records.first.name).to eq 'e'
  end

  it '#contained' do
    records = Hstore.where.store(:tags).contained(a: 2, b: 2, f: true)
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).contained(c: 'x', f: false)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'd'
  end
end

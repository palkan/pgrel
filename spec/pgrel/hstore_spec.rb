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
    Hstore.create!(name: 'f', tags: { i: [1, 2, { a: 1 }], j: { a: 1, b: [1], f: false } } )
    Hstore.create!(tags: { 1 => 2 })
    Hstore.create!(name: 'z', tags: { z: nil })
  end

  context '#where' do
    it 'simple values' do
      expect(Hstore.where.store(:tags, a: 1, b: 2).first.name).to eq 'a'
      expect(Hstore.where.store(:tags, a: 2, c: 'x').first.name).to eq 'e'
      expect(Hstore.where.store(:tags, f: false).first.name).to eq 'd'
    end

    it 'integer keys' do
      expect(Hstore.where.store(:tags, 1 => 2).size).to eq 1
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

    it 'lonely keys' do
      records = Hstore.where.store(:tags, [:z])
      expect(records.size).to eq 1
      expect(records.first.name).to eq 'z'
    end

    it 'many hashes' do
      expect(Hstore.where.store(:tags, { a: 2 }, { b: 2 }).size).to eq 3
    end

    it 'many hashes and lonely keys' do
      expect(Hstore.where.store(:tags, { a: 1 }, :z).size).to eq 2
      expect(Hstore.where.store(:tags, { a: 1 }, [:z]).size).to eq 2
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

  it '#value' do
    records = Hstore.where.store(:tags).value(1, false, [1, 2, { a: 1 }])
    expect(records.size).to eq 3
  end

  it '#values' do
    records = Hstore.where.store(:tags).values(1)
    expect(records.size).to eq 1
    expect(records.first.name).to eq 'a'

    records = Hstore.where.store(:tags).values('2', 'b')
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).values(true)
    expect(records.size).to eq 2

    records = Hstore.where.store(:tags).values([1, 2, { a: 1 }], { a: 1, b: [1], f: false })
    expect(records.size).to eq 1
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

  context '#not' do
    it '#where' do
      expect(Hstore.where.store(:tags).not(a: 2).size).to eq 6
      expect(Hstore.where.store(:tags).not(a: 1, g: 'c').size).to eq 8
    end

    it '#any' do
      expect(Hstore.where.store(:tags).not.any('a', 'f').size).to eq 3
    end

    it '#keys' do
      expect(Hstore.where.store(:tags).not.keys('a', 'f').size).to eq 7
    end
  end

  context "#update_store" do
    let(:store) { :tags }

    subject { Hstore.update_store(store) }

    it "#delete_keys" do
      subject.delete_keys(:i)
      expect(Hstore.where.store(store).keys(:i)).to_not exist

      subject.delete_keys(:a, :b)
      expect(Hstore.where.store(store).keys(:a)).to_not exist
      expect(Hstore.where.store(store).keys(:b)).to_not exist

      subject.delete_keys([:c, :d])
      expect(Hstore.where.store(store).keys(:c)).to_not exist
      expect(Hstore.where.store(store).keys(:d)).to_not exist
    end

    it "#merge" do
      subject.merge(new_key: 1)
      expect(Hstore.where.store(store).keys(:new_key).count).to be_eql Hstore.count

      subject.merge([['new_key2', 'a'], ['new_key3', 'b']])
      expect(Hstore.where.store(store).keys(:new_key2, :new_key3).count).to be_eql Hstore.count
    end

    it "#delete_pairs" do
      subject.delete_pairs(f: true, a: 1)
      expect(Hstore.where.store(store, f: true)).to_not exist
      expect(Hstore.where.store(store, a: 1)).to_not exist
      expect(Hstore.where.store(store, f: false)).to exist
      expect(Hstore.where.store(store, a: 2)).to exist
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe Jsonb do
  before(:all) do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table("jsonbs") do |t|
        t.jsonb "tags", default: {}, null: false
        t.string "name"
      end
    end

    Jsonb.reset_column_information
  end

  after { Jsonb.delete_all }

  after(:all) do
    @connection.drop_table "jsonbs", if_exists: true
  end

  let!(:setup) do
    Jsonb.create!(name: "a")
    Jsonb.create!(name: "b", tags: {a: 1, d: {e: 2}})
    Jsonb.create!(name: "c", tags: {a: 2, b: %w[c d]})
    Jsonb.create!(name: "d", tags: {a: 1, b: {c: "d", e: true}})
    Jsonb.create!(name: "e", tags: {b: 2, c: "e"})
    Jsonb.create!(name: "f", tags: {d: {e: 1, f: {h: {k: "a", s: 2}}}})
    Jsonb.create!(name: "g", tags: {f: false, g: {a: 1, b: "1"}, h: [1, "1"]})
    Jsonb.create!(name: "z", tags: {z: nil})
  end

  context "#where" do
    it "simple values" do
      expect(Jsonb.where.store(:tags, b: 2, c: "e").first.name).to eq "e"
    end

    it "nested values" do
      expect(
        Jsonb.where.store(
          :tags,
          a: 1,
          b: {c: "d", e: true}
        ).first.name
      ).to eq "d"
    end

    it "arrays (as IN)" do
      expect(Jsonb.where.store(:tags, a: [1, 2, 3]).size).to eq 3
    end

    it "lonely keys" do
      records = Jsonb.where.store(:tags, [:z])
      expect(records.size).to eq 1
      expect(records.first.name).to eq "z"
    end

    it "many hashes" do
      expect(Jsonb.where.store(:tags, {a: 2}, {b: 2}).size).to eq 2
    end

    it "many hashes and lonely keys" do
      expect(Jsonb.where.store(:tags, {a: 2}, :z).size).to eq 2
      expect(Jsonb.where.store(:tags, {a: 2}, [:z]).size).to eq 2
    end
  end

  context "#path" do
    it "pass object" do
      expect(Jsonb.where.store(:tags).path(b: {c: "d"}).first.name).to eq "d"

      expect(
        Jsonb.where.store(:tags).path(
          d: {f: {h: {s: 2}}}
        ).first.name
      ).to eq "f"
    end

    it "pass array" do
      expect(Jsonb.where.store(:tags).path(:b, :c, "d").first.name).to eq "d"
    end

    it "match object" do
      expect(
        Jsonb.where.store(:tags).path(:d, :f, :h, k: "a", s: 2).first.name
      ).to eq "f"
    end

    it "match array (as IN)" do
      expect(Jsonb.where.store(:tags).path(:d, :e, [1, 2]).size).to eq 2
      expect(Jsonb.where.store(:tags).path(d: {e: [1, 2]}).size).to eq 2
    end
  end

  it "#key" do
    records = Jsonb.where.store(:tags).key(:a)
    expect(records.size).to eq 3

    records = Jsonb.where.store(:tags).key(:c)
    expect(records.size).to eq 1
    expect(records.first.name).to eq "e"
  end

  it "#keys" do
    records = Jsonb.where.store(:tags).keys("a", "b")
    expect(records.size).to eq 2

    records = Jsonb.where.store(:tags).keys([:b, :c])
    expect(records.size).to eq 1
    expect(records.first.name).to eq "e"
  end

  describe "#overlap_values" do
    let(:records) { Jsonb.where.store(:tags).overlap_values(1, false, {e: 2}) }

    it "returns records with overlapping values" do
      expect(records.size).to eq 3
    end

    it "calls array_agg function only once" do
      expect(records.to_sql.scan(/array_agg/).count).to eq 1
    end
  end

  it "#contains_values" do
    records = Jsonb.where.store(:tags).contains_values(1)
    expect(records.size).to eq 2

    records = Jsonb.where.store(:tags).contains_values(2, "e")
    expect(records.size).to eq 1
    expect(records.first.name).to eq "e"

    records = Jsonb.where.store(:tags).contains_values(e: 1, f: {h: {k: "a", s: 2}})
    expect(records.size).to eq 1

    records = Jsonb.where.store(:tags).contains_values(false, {a: 1, b: "1"}, [1, "1"])
    expect(records.size).to eq 1
  end

  it "#any" do
    records = Jsonb.where.store(:tags).any("a", "b")
    expect(records.size).to eq 4

    records = Jsonb.where.store(:tags).any([:c, :b])
    expect(records.size).to eq 3
  end

  it "#contains" do
    records = Jsonb.where.store(:tags).contains(a: 1)
    expect(records.size).to eq 2

    records = Jsonb.where.store(:tags).contains(a: 1, b: {c: "d"})
    expect(records.size).to eq 1
    expect(records.first.name).to eq "d"
  end

  it "#contained" do
    records = Jsonb.where.store(:tags).contained(
      a: 2,
      b: 2,
      f: true,
      c: "e",
      g: "e"
    )
    expect(records.size).to eq 2

    records =
      Jsonb
        .where.store(:tags).key(:a)
        .where.store(:tags).contained(a: 2, b: %w[a b c d])

    expect(records.size).to eq 1
    expect(records.first.name).to eq "c"
  end

  context "#not" do
    it "#path" do
      expect(
        Jsonb.where.store(:tags).not.path(:d, :f, :h, k: "a", s: 2).size
      ).to eq 0
    end
  end

  context "#update_store" do
    let(:store) { :tags }

    subject { Jsonb.update_store(store) }

    it "#delete_keys" do
      subject.delete_keys(:e)
      expect(Jsonb.where.store(store).keys(:i)).to_not exist

      subject.delete_keys(:a, :b)
      expect(Jsonb.where.store(store).keys(:a)).to_not exist
      expect(Jsonb.where.store(store).keys(:b)).to_not exist

      subject.delete_keys([:c, :d])
      expect(Jsonb.where.store(store).keys(:c)).to_not exist
      expect(Jsonb.where.store(store).keys(:d)).to_not exist
    end

    it "#merge" do
      subject.merge(new_key: 1)
      expect(Jsonb.where.store(store).keys(:new_key).count).to be_eql Jsonb.count
    end

    it "#delete_pairs" do
      subject.delete_pairs(a: 1, d: {e: 2})
      expect(Jsonb.where.store(store, a: 1)).to_not exist
      expect(Jsonb.where.store(store, d: {e: 2})).to_not exist
    end
  end

  context "joins" do
    before do
      User.create!(name: "x", jsonb: Jsonb.find_by!(name: "a"))
      User.create!(name: "y", jsonb: Jsonb.find_by!(name: "b"))
      User.create!(name: "z", jsonb: Jsonb.find_by!(name: "c"))
    end

    it "works" do
      users = User.joins(:jsonb).merge(Jsonb.where.store(:tags).key(:a))
      expect(users.size).to eq 2
      expect(users.map(&:name)).to match_array(["y", "z"])
    end

    it "works with #path" do
      users = User.joins(:jsonb).merge(Jsonb.where.store(:tags).path(:a, 2))
      expect(users.size).to eq 1
      expect(users.map(&:name)).to match_array(["z"])
    end

    it "works with #contains_values" do
      users = User.joins(:jsonb).merge(Jsonb.where.store(:tags).contains_values(1))
      expect(users.size).to eq 1
      expect(users.map(&:name)).to match_array(["y"])
    end
  end
end

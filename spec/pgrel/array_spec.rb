# frozen_string_literal: true

require "spec_helper"

describe ArrayStore do
  before(:all) do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table("array_stores") do |t|
        t.string "tags", default: [], null: false, array: true
        t.string "name"
      end
    end

    ArrayStore.reset_column_information
  end

  after { ArrayStore.delete_all }

  after(:all) do
    @connection.drop_table "array_stores", if_exists: true
  end

  let!(:setup) do
    ArrayStore.create!(name: "a", tags: [1, 2, "a", "b"])
    ArrayStore.create!(name: "b", tags: [2, "b", "e"])
    ArrayStore.create!(name: "c", tags: ["b"])
    ArrayStore.create!(name: "d")
    ArrayStore.create!(name: "e", tags: [2, "x", "c"])
  end

  context "#overlap" do
    it "single simple argument" do
      records = ArrayStore.where.store(:tags).overlap(:b)
      expect(records.size).to eq 3
    end

    it "several arguments" do
      records = ArrayStore.where.store(:tags).overlap("a", 1)
      expect(records.size).to eq 1
      expect(records.first.name).to eq "a"
    end

    it "single array argument" do
      records = ArrayStore.where.store(:tags).overlap([1, "x"])
      expect(records.size).to eq 2
    end
  end

  it "#contains" do
    records = ArrayStore.where.store(:tags).contains([2, "b"])
    expect(records.size).to eq 2

    records = ArrayStore.where.store(:tags).contains([2, "x"])
    expect(records.size).to eq 1
    expect(records.first.name).to eq "e"
  end

  it "#contained" do
    records = ArrayStore.where.store(:tags).contained([1, 2, "a", "b"])
    expect(records.size).to eq 3
    expect(records.detect { |r| r.name == "d" }).not_to be_nil

    records = ArrayStore.where.store(:tags).contained([])
    expect(records.size).to eq 1
    expect(records.first.name).to eq "d"
  end

  context "#not" do
    it "#overlap" do
      expect(ArrayStore.where.store(:tags).not.overlap("b", 2).size).to eq 1
    end
  end

  context "joins" do
    before do
      User.create!(name: "x", array_store: ArrayStore.find_by!(name: "a"))
      User.create!(name: "y", array_store: ArrayStore.find_by!(name: "b"))
      User.create!(name: "z", array_store: ArrayStore.find_by!(name: "c"))
    end

    it "works" do
      users = User.joins(:array_store).merge(ArrayStore.where.store(:tags).overlap(2))
      expect(users.size).to eq 2
      expect(users.map(&:name)).to match_array(["x", "y"])
    end
  end
end

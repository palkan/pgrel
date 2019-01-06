ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :tags
    t.integer :jsonb_id
    t.integer :array_store_id
    t.integer :hstore_id
    t.timestamps null: true
  end
end

class User < ActiveRecord::Base
  belongs_to :jsonb
  belongs_to :array_store
  belongs_to :hstore
end

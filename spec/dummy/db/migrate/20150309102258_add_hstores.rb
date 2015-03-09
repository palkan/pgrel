class AddHstores < ActiveRecord::Migration
  def change
    create_table :hstores do |t|
      t.hstore :tags, default: '', null: false
      t.string :name
    end
  end
end

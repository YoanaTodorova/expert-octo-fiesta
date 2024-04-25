class CreateCachedSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :cached_searches do |t|
      t.text :query_string, null: false, index: true
      t.integer :hit_count, null: false, default: 0

      t.timestamps
    end
  end
end

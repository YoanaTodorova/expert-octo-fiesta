class AddProcessedPagesAndTotalCountToCachedSearches < ActiveRecord::Migration[7.1]
  def change
    add_column :cached_searches, :processed_pages_count, :integer, default: 0
    add_column :cached_searches, :total_pages_count, :integer, default: 0
  end
end

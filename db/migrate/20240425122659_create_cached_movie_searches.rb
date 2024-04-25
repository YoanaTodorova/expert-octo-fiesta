class CreateCachedMovieSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :cached_movie_searches do |t|
      t.references :cached_search, index: true, foreign_key: true
      t.references :movie, index: true, foreign_key: true

      t.timestamps
    end

    add_index :cached_movie_searches, [:cached_search_id, :movie_id], unique: true
  end
end

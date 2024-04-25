class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :title, null: false
      t.text :overview
      t.string :external_id, null: false, index: true

      t.timestamps
    end
  end
end

class CreateTvSeries < ActiveRecord::Migration
  def change
    create_table :tv_series do |t|
      t.string :name, :limit => 250
      t.string :original_name, :limit => 250
      t.string :description, :limit => 10.kilobyte

      t.string :poster_url
      t.integer :poster_file_id

      t.integer :tmdb_id
      t.string :imdb_id
      t.string :freebase_id

      t.timestamps
    end
  end
end

class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.column :release_date, :date
      t.column :title, :string, :limit => 1024
      t.column :original_title, :string, :limit => 1024
      t.column :tagline, :string, :limit => 2048
      t.column :storyline, :text
#      t.column :language, :string, :limit => 100
#      t.column :trailer_url, :string, :limit => 2048
      t.string :youtube_trailer_source, :limit => 100

      t.integer :poster_file_id
      t.column :poster_url, :string, :limit => 2048

      t.column :tmdb_id, :string, :limit => 100
      t.column :tmdb_updated, :date
      t.column :imdb_id, :string, :limit => 100
      t.column :imdb_updated, :date
      t.column :metacritic_id, :string, :limit => 100
      t.column :metacritic_updated, :date
      t.column :rotten_tomatoes_id, :string, :limit => 100
      t.column :rotten_tomatoes_updated, :date

      t.timestamps
    end
  end
end

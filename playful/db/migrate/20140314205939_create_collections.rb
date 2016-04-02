class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string  :sti_type
      t.string  :name
      t.string  :description, :limit => 10.kilobyte
      t.string  :poster_url
      t.integer :poster_file_id
      t.timestamps

      # tv series season
      t.date        :air_date
      t.references  :tv_series
      t.string      :freebase_id
      t.integer     :tmdb_id
      t.integer     :season_number

      # audio release
      t.string    :release_type
      t.string    :spotify_id
      t.integer   :year
      t.string    :artist
      t.string    :front_cover_id
      t.string    :back_cover_id
      t.integer   :track_total
      t.string    :genre
      t.integer   :disc_total
      t.boolean   :is_compilation

    end
  end
end

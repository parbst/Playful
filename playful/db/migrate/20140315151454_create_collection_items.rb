class CreateCollectionItems < ActiveRecord::Migration
  def change
    create_table :collection_items do |t|
      t.column :sti_type, :string
      t.references :base_files
      t.integer :collection_id
      t.integer :item_order
      t.string :item_name
      t.string :item_description, :limit => 10.kilobyte
      t.timestamps

      # tv series episode

      t.date :air_date
      t.string :poster_url
      t.integer :poster_file_id
      t.integer :tmdb_id
      t.string :freebase_id
      t.string :imdb_id
      t.integer :episode_number
      t.references :tv_series

      # audio track

      t.string    :artist
      t.string    :spotify_id
      t.string    :composer
      t.integer   :disc_number
      t.string    :comment
      t.datetime  :year

    end
  end
end

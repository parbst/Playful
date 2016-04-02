class CreateCasts < ActiveRecord::Migration
  def change
    create_table :casts do |t|
      t.belongs_to :movie
      t.belongs_to :actor
      t.belongs_to :tv_series
#      t.belongs_to :collection
#      t.belongs_to :collection_item
      t.column :character_name, :string, :limit => 512
      t.integer :image_file_id
      t.integer :season_id
      t.integer :episode_id
      t.column :character_image_url, :string, :limit => 2048
      t.integer :order

      t.timestamps
    end
  end
end

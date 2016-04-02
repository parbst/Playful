class CreateGenres < ActiveRecord::Migration
  def change
    create_table :genres do |t|
      t.column :name, :string, :limit => 2048
      t.column :tmdb_id, :integer

      t.timestamps
    end
  end
end

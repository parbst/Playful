class CreateActors < ActiveRecord::Migration
  def change
    create_table :actors do |t|
      t.column :name, :string, :limit => 2048
      t.column :image_url, :string, :limit => 2048

      t.timestamps
    end
  end
end

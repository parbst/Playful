class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.column :name, :string, :limit => 1024
      t.column :category, :string, :limit => 1024
      t.column :value, :text
      t.column :value_type, :string

      t.timestamps
    end
  end
end

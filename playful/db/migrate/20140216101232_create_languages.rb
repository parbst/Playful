class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.column :iso_639_1, :string, limit: 20
      t.column :name, :string

      t.timestamps
    end
  end
end

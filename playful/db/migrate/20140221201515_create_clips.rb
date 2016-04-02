class CreateClips < ActiveRecord::Migration
  def change
    create_table :clips do |t|
      t.string  :sti_type
      t.belongs_to :movie
      t.belongs_to :collection_item
      t.belongs_to :base_file
      t.integer :order
      t.integer :set
      t.string :name
      t.boolean :primary_track, default: false

      t.timestamps
    end
  end
end

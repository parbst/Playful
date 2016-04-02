class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.column :sti_type, :string

      t.references :order
      t.column :status, :string, :null => false
      t.column :message, :string
      t.column :backtrace, :text
      t.column :sequence, :integer, :null => false

      # move file task
      t.column :from_path, :string, :limit => 1024
      t.column :create_missing_dirs, :boolean, :default => false #, :null => false
      t.column :overwrite_existing, :boolean, :default => false #, :null => false

      # edit tags task
      t.column :old_tags, :text
      t.column :new_tags, :text

      # download task
      t.column :url, :string, :limit => 4.kilobyte

      # model tasks
      t.column :model_id, :integer
      t.column :model_type, :string

      # update tasks
      t.column :update_type, :string, :limit => 30

      # common fields
      t.references :base_file
      t.column :to_path, :string, :limit => 4.kilobyte
      t.column :path, :string, :limit => 4.kilobyte
      t.references :share

      # model
      t.boolean :should_retrieve
      t.boolean :overwrite_model_values
      t.column :store_video_clip, :text
      t.column :store_audio_clip, :text
      t.column :model_store, :text

      t.timestamps
    end
  end
end

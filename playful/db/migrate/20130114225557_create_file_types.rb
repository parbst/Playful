class CreateFileTypes < ActiveRecord::Migration
  def change
    create_table :file_types do |t|
      t.column :name,       :string, :limit => 50,  :null => false    # name of the file type eg. MPEG4 Audio
      t.column :subtype,    :string, :limit => 50,  :null => false    # name of the type in playful eg. Audio or Image
      t.column :extension,  :string, :limit => 20,  :null => false	  # name of the filetypes suffix without the period eg. nfo or txt
      t.column :ruby_class, :string, :limit => 50,	:null => false    # name of the active record class this filetype should map to eg. VideoFile
      t.column :mime_type,  :string, :limit => 250,	:null => false    # the mime type this file should have when served on the web
      t.column :scan_type,  :string, :limit => 100, :null => false    # corresponds to the :format string returned from the file scanner

      t.timestamps
    end
  end
end

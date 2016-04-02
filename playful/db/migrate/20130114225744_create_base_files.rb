class CreateBaseFiles < ActiveRecord::Migration
  def change
    #, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8'
    create_table :base_files do |t|
      t.references :file_type
      t.references :share
      t.column :sti_type, :string

      # base file fields
      t.column :path, :string, :limit => 1024, :null => false
      t.column :uid, :integer
      t.column :gid, :integer
      t.column :inode, :integer
      t.column :links, :integer
      t.column :byte_size, :huge_integer, :null => false
      t.column :block_size, :integer
      t.column :blocks, :integer
      t.column :access_time, :datetime, :null => false
      t.column :change_time, :datetime, :null => false
      t.column :modification_time, :datetime, :null => false
      t.column :md5hash, :string, :limit => 32

      # audio file fields
      t.column :artist, :string, :limit => 150
      t.column :album_artist, :string, :limit => 150
      t.column :composer, :string, :limit => 150
      t.column :album, :string, :limit => 150
      t.column :track_title, :string, :limit => 200
      t.column :track_number, :integer
      t.column :track_total, :integer
      t.column :disc_number, :integer
      t.column :disc_total, :integer
      t.column :comment, :string, :limit => 512
      t.column :year, :datetime
      t.column :genre, :string, :limit => 50
      t.column :bit_rate_type, :string, :limit => 10                      # VBR (variable bit rate) or CBR (constant bit rate)
      t.column :bit_rate, :integer
      t.column :sample_rate, :integer 
      t.column :channel_mode, :string, :limit => 20                       # for instance stereo/2-channels
      t.column :duration, :decimal                                        # in seconds.fractions of a second
      t.column :album_art, :binary, :limit => 500.kilobytes

      # video file fields
      t.column :audio_channel, :string, :limit => 30                          # number of audio channels
      t.column :audio_codec, :string, :limit => 30                  
      t.column :audio_sample_rate, :integer                  
      t.column :audio_sample_units, :string, :limit => 20                     # most likely Hz
      t.column :bit_rate, :integer
      t.column :bit_rate_units, :string, :limit => 20                         # most likely kB/s
      t.column :container_format, :string, :limit => 20                       # for instance avi
      t.column :duration, :decimal                                            # in seconds.fractions of a second
      t.column :frames_per_second, :decimal                  
      t.column :video_codec, :string, :limit => 20                            # for instance mpeg4
      t.column :video_colorspace, :string, :limit => 20                       # for instance yuv420p

      # image file fields
#      t.column :height, :integer, :null => false
#      t.column :width, :integer, :null => false
      t.column :captured_at, :datetime
      t.column :exif_comment, :string, :limit => 250
      t.column :camera_make, :string, :limit => 50
      t.column :camera_model, :string, :limit => 50
      t.column :title, :string, :limit => 150

      # shared fields
      t.column :height, :integer                  
      t.column :width, :integer                  

      t.timestamps
    end
  end
end

class BaseFile::VideoFile < BaseFile

  validates :audio_channel, :audio_codec, :audio_sample_rate, :audio_sample_units, :bit_rate, :bit_rate_units,
            :container_format, :duration, :frames_per_second, :video_codec, :video_colorspace, :presence => true
  validates :audio_channel, :inclusion => { :in => %w(mono stereo 5.1 7.1) }
  validates :audio_sample_units, :inclusion => { :in => %w(Hz kHz) }
  validates :bit_rate_units, :inclusion => { :in => %w(kb/s Mb/s b/s) }
  validates :height, :width, :numericality => { :only_integer => true }

  has_many :video_clips, :foreign_key => 'base_file_id'
  has_many :movies, :through => :video_clips
  has_many :collection_items, :through => :video_clips

  searchable do
    string  :audio_channel, :audio_codec, :audio_sample_units, :bit_rate_units, :container_format, :video_codec, :video_colorspace
    integer :audio_sample_rate, :bit_rate
    double  :duration, :frames_per_second
  end

  def resolved_path
    if movies.any?
      ::Playful::PathResolver::Video.path_for_file(self, movie: movies.first)
    elsif collection_items.any? && collection_items.first.is_a?(Episode)
      ::Playful::PathResolver::Video.path_for_file(self, episode: collection_items.first)
    else
      super()
    end
  end

  def update_from_scan(scan)
    super(scan)
    ffmpeg = scan[:ffmpeg]
    if scan[:is_video] && !ffmpeg.nil?
      audio = ffmpeg[:audio]
      video = ffmpeg[:video]
      br_in_kbps = ffmpeg[:bit_rate_in_kilo_bytes_per_sec]
      self.bit_rate = br_in_kbps
      self.bit_rate_units = 'kb/s' unless br_in_kbps.nil?
      self.duration = ffmpeg[:duration]
      self.container_format = ffmpeg[:format]

      unless audio.nil?
        self.audio_channel = audio[:channels]
        self.audio_sample_rate = audio[:sample_rate_in_hz]
        self.audio_sample_units = 'Hz' unless audio[:sample_rate_in_hz].nil?
        if audio[:format] =~ /^(.+) \(/
          self.audio_codec = $1
        end
      end

      unless video.nil?
        self.frames_per_second = video[:fps]
        self.video_colorspace = video[:color_mode]
        self.height = video[:height]
        self.width = video[:width]
        self.video_codec = video[:format]
      end
    end
  end

end

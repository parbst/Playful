require 'units'

class BaseFile::AudioFile < BaseFile

  validates :track_title, :channel_mode, :presence => true, :unless => 'reference_track.nil?'
  validates :artist, :presence => true, :if => 'album_artist.blank? && !reference_track.nil?'
  validates :album_artist, :presence => true, :if => 'artist.blank? && !reference_track.nil?'
  validates :year, :presence => true, :unless => 'album.blank?'
  validates :track_number, :numericality => { :only_integer => true }, :unless => 'album.blank?'
  validates :track_total, :numericality => { :only_integer => true }, :unless => 'album.blank?'
  validates :disc_number, :numericality => { :only_integer => true }, :unless => 'album.blank?'
  validates :disc_total, :numericality => { :only_integer => true }, :unless => 'album.blank?'
  validates :bit_rate_type, :inclusion => { :in => %w(cbr vbr) }
  validates :channel_mode, :inclusion => { :in => %w(mono stereo) }
  validates :sample_rate, :bit_rate, :numericality => { :only_integer => true }
  validates :duration, :numericality => true

  has_many :audio_clips, foreign_key: 'base_file_id'
  has_many :collection_items, through: :audio_clips
  alias_attribute :tracks, :collection_items

  searchable do
    text    :track_title, :artist, :album_artist, :composer, :album, :comment, :genre
    integer :track_number, :track_total, :disc_number, :disc_total, :sample_rate, :bit_rate, :sample_rate
    time    :created_at, :updated_at, :year
    double  :duration
    string  :bit_rate_type, :channel_mode
  end

  def resolved_path
    ::Playful::PathResolver::Audio.path_for_file(self)
  end

  def update_from_scan(scan)
    super(scan)
    if scan.has_key?(:tag)
      [:artist, :album_artist, :composer, :album, :track_title, :track_number, :track_total,
       :year, :genre, :disc_number, :disc_total, :comment, :duration].each do |key|
        self[key] = scan[:tag][key]
      end
      self[:bit_rate_type] = scan[:tag][:variable_bit_rate] ? 'vbr' : 'cbr'
    end
    if scan.has_key?(:ffmpeg)
      self[:bit_rate] = scan[:ffmpeg][:bit_rate_in_kilo_bytes_per_sec]
      if scan[:ffmpeg].has_key?(:audio)
        self[:sample_rate] = scan[:ffmpeg][:audio][:sample_rate_in_hz]
        self[:channel_mode] = scan[:ffmpeg][:audio][:channels]
      end
    end
  end

  def reference_track
    primary = audio_clips.where(:primary_track => true).first
    primary && primary.track || tracks.order(:id).first
  end

  def update_from_relations
    tag_from_relations
    scan_and_update
  end

  def tag_from_relations
    track = reference_track

    args = Hash[[:artist, :composer, :track_number, :disc_number, :comment, :year].map { |k| [k, track.send(k)] }]
    args[:track_title] = track.title
    unless track.release.nil?
      [:track_total, :genre, :disc_total].each { |k| args[k] = track.release.send(k) }
      args[:album_artist] = track.release.artist
      args[:album] = track.release.title
      args[:year] ||= track.release.year
      unless track.release.front_cover.nil?
        args[:cover_art][:front] = track.release.front_cover.path
      end
      if args[:disc_total].nil?
        args[:disc_total] = 1
      end
    end

    write_tags(args)
  end

  def write_tags(args)
    tag_driver = Playful::File::Driver::TagDriver.new
    tag_driver.write_tags(path, args)
  end

end

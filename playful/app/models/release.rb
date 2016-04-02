class Release < Collection
  alias_attribute :title, :name
  alias_attribute :tracks, :collection_items

  belongs_to :front_cover, class_name: 'BaseFile::ImageFile', inverse_of: :album_front_covers
  belongs_to :back_cover, class_name: 'BaseFile::ImageFile', inverse_of: :album_back_covers

  validates :release_type, inclusion: { in: %w(EP Album Single) , message: "%{value} is not a valid release type" }
  validates :track_total, :disc_total, numericality: { only_integer: true }
  validates :artist, :name, presence: true

  before_validation :ensure_defaults, :on => :create

  searchable do
    text    :title, :description, :artist
    integer :disc_total, :track_total
    string  :release_type, :genre
    time    :created_at, :updated_at, :year
  end

  def self.searchable_ids
    {
      title:      self.respond_to?(:title) && self.title,
      spotify_id: self.respond_to?(:spotify_id) && self.spotify_id
    }
  end

  def metadata_lookup_args
    {}.tap do |o|
      o[:spotify] = { release_id: self.spotify_id } unless self.spotify_id.nil?
    end
  end

  def update_from_metadata(scan, overwrite_with_nil = false)
    self.spotify_id = scan[:identifier][:spotify][:release_id] if scan.has_path?('identifier.spotify.release_id')
    self.title = scan[:release_name] unless scan[:release_name].nil?
    self.year = scan[:release_date] unless scan[:release_date].nil?
    self.artist = scan[:artists].first[:artist_name] if scan[:artists].is_a?(Array) && scan[:artists].length == 1
    self.track_total = scan[:tracks].length if scan[:tracks].is_a?(Array)
    unless scan[:release_type].blank?
      release_type = scan[:release_type]
      release_type[0] = release_type[0].capitalize
      self.release_type = release_type
    end
    update_tracks_from_metadata(scan)
  end

  def update_tracks_from_metadata(scan)
    if scan[:tracks].is_a?(Array)
      scan[:tracks].select{ |t| !t[:track_number].nil? }.each do |track_metadata|
        track = self.tracks.select { |t| t.track_number == track_metadata[:track_number]}.first
        track.update_from_metadata(track_metadata) if track
      end
    end
  end

  def self.valid_creation_data?(params)
    params.is_a?(Hash) && (params[:artist].is_a?(String) || params[:is_compilation] || params[:spotify_id])
  end

  private

  def ensure_defaults
    self.track_total ||= (tracks || []).length
    self.is_compilation = false if self.is_compilation.nil?
    true # because a before_validation hook that returns false, causes a message-less validation error
  end

end

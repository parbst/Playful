class Track < CollectionItem

  alias_attribute :title, :item_name
  alias_attribute :track_number, :item_order
  alias_attribute :release, :collection
  alias_attribute :release_id, :collection_id
  has_many :audio_clips, foreign_key: :collection_item_id
  has_many :audio_files, through: :audio_clips

  validates :disc_number, numericality: { only_integer: true }, unless: 'disc_number.blank?'
  validates :track_number, numericality: { only_integer: true }, unless: 'track_number.blank?'
  validates :title, presence: true
  validates :artist, presence: true, :if => "release.blank? || release.artist.blank?"

  searchable do
    # TODO: make delegates so a track can be found by for instance it's album artist. delegate :name, :age, to: :profile
    # http://rahil.ca/blog/how-to-set-up-a-rails-search-api-with-json-and-sunspot-solr/#searchable
    text    :title, :artist, :comment, :composer
    integer :track_number, :disc_number
    time    :created_at, :updated_at, :year
  end

  def resolve_clips!
    audio_clips.sort_by {|ac| ac.primary_track ? 1 : -1; }.map(&:audio_file).each(&:resolve_path!)
  end

  def update_from_metadata(scan, overwrite_with_nil = false)
    [:title, :disc_number].each do |key|
      self.attributes = { key => scan[key] } unless scan[key].nil? && !overwrite_with_nil
    end

    if scan[:artists].is_a?(Array) && scan[:artists].length == 1
      self.artist = scan[:artists].first[:artist_name]
    end

    if scan[:identifier].is_a?(Hash) && scan[:identifier][:spotify].is_a?(Hash) && scan[:identifier][:spotify][:track_id]
      self.spotify_id = scan[:identifier][:spotify][:track_id]
    end
  end

end

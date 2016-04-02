class Episode < CollectionItem
  include EasySetters

  alias_attribute :name, :item_name # TODO: kill this name attribute. it should be called title
  alias_attribute :title, :item_name
  alias_attribute :description, :item_description

  belongs_to :poster_file, :class_name => 'BaseFile::ImageFile'
  belongs_to :tv_series
  has_many :video_clips, foreign_key: :collection_item_id
  has_many :video_files, through: :video_clips
  has_many :casts, :dependent => :destroy
  has_many :actors, :through => :casts

  alias_attribute :season, :collection

  before_validation :ensure_item_order

  validates :episode_number, :season, :presence => true
  validates :episode_number, uniqueness: { scope: :tv_series_id, message: 'episode numbers must be unique within a season' }

  searchable do
    text    :title, :description
    integer :episode_number
    time    :created_at, :updated_at
  end

  def resolve_clips
    video_files.each(&:resolve_path!)
  end

  def update_from_metadata(metadata, overwrite_with_nil = false)
    fields = [:item_order, :name, :description, :poster_url, :air_date] + self.class.searchable_ids.keys

    values = Hash[fields.map {|f| [f, metadata[f]]}]
    self.attributes = values.delete_if { |_, v| v.nil? && !overwrite_with_nil }

    add_casts(metadata[:casts])
  end

  def metadata_lookup_args
    {}.tap do |o|
      unless season.nil? || season.season_number.nil? || episode_number.nil?
        o[:tmdb] = {
          tv_series_id:     !tv_series.nil? && tv_series.tmdb_id || !season.nil? && season.tv_series.tmdb_id,
          season_number:    season.season_number,
          episode_number:   episode_number
        }
      end
    end
  end

  def self.searchable_ids
    {
      episode_number: self.respond_to?(:episode_number) && self.episode_number,
      tmdb_id:        self.respond_to?(:tmdb_id) && self.tmdb_id,
      freebase_id:    self.respond_to?(:freebase_id) && self.freebase_id,
      imdb_id:        self.respond_to?(:imdb_id) && self.imdb_id
    }
  end

  def self.valid_creation_data?(params)
    params.has_shape?({
      name:                 String,
      description:          String,
      order:                Integer,
      air_date:             Date,
      poster_url:           String,
      poster_file_id:       Integer,
      episode_number:       Integer,
      tmdb_id:              Integer,
      freebase_id:          String,
      imdb_id:              String,
      update_from_metadata: Boolean
    })
  end

  def ensure_item_order
    self.item_order ||= episode_number
  end
end

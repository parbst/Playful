class Season < Collection
  include EasySetters

  belongs_to :tv_series
  has_many :casts, :dependent => :destroy
  has_many :actors, :through => :casts
  alias_attribute :episodes, :collection_items
  alias_attribute :title, :name

  validates :season_number, :tv_series, :presence => true
  validates :season_number, uniqueness: { scope: :tv_series_id, message: 'season numbers must be unique within a tv series' }

  searchable do
    text    :title, :description
    integer :season_number
    time    :created_at, :updated_at, :air_date
  end

  def update_from_metadata(metadata, overwrite_with_nil = false)
    fields = [:name, :description, :poster_url, :air_date] + self.class.searchable_ids.keys

    values = Hash[fields.map { |f| [f, metadata[f]] }]
    self.attributes = values.delete_if { |_, v| v.nil? && !overwrite_with_nil }

    add_casts(metadata[:casts])
  end

  def metadata_lookup_args
    {}.tap do |o|
      if !self.tmdb_id.nil? || !self.season_number.nil?
        o[:tmdb] = { tv_series_id: tv_series.tmdb_id, season_number: self.season_number }
      end
    end
  end

  validates :tv_series, :presence => true

  def self.searchable_ids
    {
      freebase_id:    self.respond_to?(:freebase_id) && self.freebase_id,
      tmdb_id:        self.respond_to?(:tmdb_id) && self.tmdb_id,
      season_number:  self.respond_to?(:season_number) && self.season_number
    }
  end

  def self.valid_creation_data?(params)
    params.has_shape?({
      name:                   String,
      description:            String,
      poster_url:             String,
      poster_file_id:         Integer,
      freebase_id:            String,
      tmdb_id:                Integer,
      air_date:               Date,
      season_number:          Integer,
      update_from_metadata:   Boolean
    })
  end
end

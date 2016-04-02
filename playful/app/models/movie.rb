class Movie < ActiveRecord::Base
  include EasySetters

  has_and_belongs_to_many :genres
  has_and_belongs_to_many :languages
  has_many :casts, :dependent => :destroy
  has_many :actors, :through => :casts
  belongs_to :poster_file, class_name: 'BaseFile::ImageFile', inverse_of: :movies
  has_many :video_clips, :dependent => :destroy
  has_many :video_files, through: :video_clips

  before_validation :ensure_defaults, :on => :create

  validates :title, :original_title, :presence => true

  searchable do
    text    :title, :original_title, :tagline, :storyline
    time    :created_at, :updated_at, :release_date
  end

  def resolve_clips
    video_files.each(&:resolve_path!)
  end

  def self.searchable_ids
    {
      tmdb_id:            self.respond_to?(:tmdb_id) && self.tmdb_id,
      imdb_id:            self.respond_to?(:imdb_id) && self.imdb_id,
      rotten_tomatoes_id: self.respond_to?(:rotten_tomatoes_id) && self.rotten_tomatoes_id,
      metacritic_id:      self.respond_to?(:metacritic_id) && self.metacritic_id,
      title:              self.respond_to?(:title) && self.title
    }
  end

  def update_from_metadata(metadata, overwrite_with_nil = false)
    fields = [:release_date, :original_title, :tagline, :storyline, :youtube_trailer_source, :tmdb_updated,
              :rotten_tomatoes_update, :metacritic_updated] + self.class.searchable_ids.keys

    values = Hash[fields.map {|f| [f, metadata[f]] }]
    self.attributes = values.delete_if { |_, v| v.nil? && !overwrite_with_nil }

    add_languages(metadata[:languages])
    add_genres(metadata[:genres])
    add_casts(metadata[:casts])

    tmdb_posters = metadata[:tmdb_posters]
    if tmdb_posters.is_a?(Array)
      self.poster_url = tmdb_posters.select { |url| url =~ /w342/ }.first
    end
  end

  def ensure_defaults
    self.original_title = title if original_title.nil?
  end

end

class TvSeries < ActiveRecord::Base
  include EasySetters

  alias_attribute :title, :name # kill these name attributes
  alias_attribute :original_title, :original_name

  has_and_belongs_to_many :genres
  has_and_belongs_to_many :languages
  has_many :seasons, :dependent => :destroy
  belongs_to :poster_file, :class_name => 'BaseFile::ImageFile'
  has_many :casts, :dependent => :destroy
  has_many :actors, :through => :casts

  searchable do
    text    :title, :description, :original_title
    time    :created_at, :updated_at
  end

  def metadata_lookup_args
    {}.tap do |o|
      o[:tmdb] = { tv_series_id: self.tmdb_id } unless self.tmdb_id.nil?
      o[:text] = { tv_series_title: self.name } unless self.name.nil?
    end
  end

  def update_from_metadata(metadata, overwrite_with_nil = false)
    fields = [:original_name, :description, :poster_url, :poster_file_id] + self.class.searchable_ids.keys

    values = Hash[fields.map { |f| [f, metadata[f]] }]
    self.attributes = values.delete_if { |_, v| v.nil? && !overwrite_with_nil }

    add_languages(metadata[:spoken_languages])
    add_genres(metadata[:genres])
    add_casts(metadata[:casts])

    tmdb_posters = metadata[:tmdb_posters]
    if tmdb_posters.is_a?(Array)
      self.poster_url = tmdb_posters.select { |url| url =~ /w342/ }.first
    end
  end

  def self.searchable_ids
    {
      imdb_id:      self.respond_to?(:imdb_id) && self.imdb_id,
      tmdb_id:      self.respond_to?(:tmdb_id) && self.tmdb_id,
      freebase_id:  self.respond_to?(:freebase_id) && self.freebase_id,
      name:         self.respond_to?(:name) && self.name
    }
  end

  def self.valid_creation_data?(params)
    params.has_shape?({
      name:             String,
      original_name:    String,
      description:      String,
      poster_url:       String,
      poster_file_id:   Integer,
      tmdb_id:          Integer,
      imdb_id:          String,
      freebase_id:      String
    })
  end

end

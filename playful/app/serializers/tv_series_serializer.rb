class TvSeriesSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :title, :original_title, :description, :poster_url, :tmdb_id, :imdb_id, :freebase_id

  has_one :poster_file
  has_many :seasons
  has_many :casts
  has_many :languages
  has_many :genres
end

class MovieSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :title, :original_title, :tagline, :storyline, :release_date, :created_at, :updated_at,
             :youtube_trailer_source, :poster_url, :tmdb_id, :tmdb_updated, :imdb_id, :imdb_updated, :metacritic_id,
             :metacritic_updated, :rotten_tomatoes_id, :rotten_tomatoes_updated

  has_one :poster_file
  has_many :genres
  has_many :languages

end

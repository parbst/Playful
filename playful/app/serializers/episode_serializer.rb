class EpisodeSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :title, :air_date, :created_at, :updated_at, :description, :poster_url,
             :episode_number, :freebase_id, :tmdb_id, :imdb_id

  has_one :poster_file
  has_one :tv_series
  has_one :season

  has_many :video_files
  has_many :casts

end

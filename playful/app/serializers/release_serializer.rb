class ReleaseSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :release_type, :spotify_id, :year, :artist, :track_total, :genre, :disc_total, :is_compilation,
             :title, :description

  has_one :front_cover
  has_one :back_cover
  has_many :tracks
end

class TrackSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :title, :track_number, :artist, :spotify_id, :composer, :disc_number, :comment, :year

  has_one :release
  has_many :audio_files
end

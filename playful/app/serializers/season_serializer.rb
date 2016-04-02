class SeasonSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :title

  has_one :tv_series
  has_many :episodes
  has_many :casts
end

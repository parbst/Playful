class Genre < ActiveRecord::Base
  has_and_belongs_to_many :movies

  validates :name, :uniqueness => true

  def self.ensure(params)
    g = params.has_key?(:tmdb_id) ? Genre.where(tmdb_id: params[:tmdb_id]).first : nil
    g ||= params.has_key?(:name) ? Genre.find_by_name(params[:name]) : nil
    g ||= Genre.new(params)
    g.tmdb_id = params[:tmdb_id] if g.tmdb_id.nil? && params.has_key?(:tmdb_id)
    g
  end

  def self.valid_creation_data?(params)
    shape = { name: String, tmdb_id: Integer }
    params.has_shape?(shape)
  end
end

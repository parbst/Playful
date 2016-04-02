class Language < ActiveRecord::Base
  has_and_belongs_to_many :movies

  validates :iso_639_1, uniqueness: true
  validates :name, :iso_639_1, :presence => true

  def self.ensure(params)
    l = params.has_key?(:iso_639_1) ? Language.find_by_iso_639_1(params[:iso_639_1]) : nil
    if l.nil?
      l = Language.new(params.slice(:name, :iso_639_1))
    end
    l
  end

  def self.valid_creation_data?(params)
    lang_shape = { name: String, iso_639_1: String }
    params.has_shape?(lang_shape)
  end
end

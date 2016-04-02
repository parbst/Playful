class Actor < ActiveRecord::Base
  has_many :casts
  has_many :movies, :through => :casts

  def self.ensure(params)
    a = Actor.find_by_name(params[:name])
    a.nil? ? Actor.new(params) : a
  end

  def self.valid_creation_data?(params)
    shape = { name: String, image_url: String }
    params.has_shape?(shape, { allow_undefined_keys: true, allow_missing_keys: true, allow_nil_values: false, error_on_mismatch: false })
  end
end

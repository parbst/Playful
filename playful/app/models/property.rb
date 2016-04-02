class Property < ActiveRecord::Base
  validates :category, :inclusion => {:in => ['configuration'], :message => '%{value} is not an accepted category'}
end

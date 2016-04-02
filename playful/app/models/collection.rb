class Collection < ActiveRecord::Base

  self.inheritance_column = 'sti_type'
  has_many :collection_items
  belongs_to :poster_file, :class_name => 'BaseFile::ImageFile'

end

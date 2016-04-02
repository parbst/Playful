class CollectionItem < ActiveRecord::Base

  self.inheritance_column = 'sti_type'
  belongs_to :base_file
  belongs_to :collection

end

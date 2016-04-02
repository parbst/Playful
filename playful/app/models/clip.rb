class Clip < ActiveRecord::Base

  belongs_to :movie
  belongs_to :collection_item
  self.inheritance_column = 'sti_type'

  validates :movie_id, :presence => true, :if => 'collection_item_id.nil?'
  validates :collection_item_id, :presence => true, :if => 'movie_id.nil?'
  validates :movie_id, :uniqueness => { :scope => :base_file_id }, :unless => 'movie_id.nil?'
  validates :collection_item_id, :uniqueness => { :scope => :base_file_id }, :unless => 'collection_item_id.nil?'

end

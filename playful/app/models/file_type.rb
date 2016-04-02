class FileType < ActiveRecord::Base
  has_many :base_files

  validates_uniqueness_of :name
  validates_presence_of :name, :subtype, :extension, :ruby_class, :mime_type, :scan_type
  validates_format_of :mime_type, :with => /^[^\/]+\/[^\/]+(\s*,\s*[^\/]+\/[^\/]+)*?$/, :multiline => true

  AUDIO = 'Audio'
  IMAGE = 'Image'
  VIDEO = 'Video'
end

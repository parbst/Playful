require 'tempfile'
require 'playful/path_resolver'

class BaseFile < ActiveRecord::Base

  belongs_to :file_type
  belongs_to :share
  self.inheritance_column = 'sti_type'

  validates_presence_of :byte_size, :access_time, :change_time, :modification_time, :path, :share_id, :file_type_id
  validates_length_of :md5hash, :is => 32, :allow_nil => true, :message => 'MD5 hashes are exactly 32 chars long.'
  validates_numericality_of :byte_size, :only_integer => true, :greater_than_or_equal_to => 0
  validate :file_exists
  validate :file_belongs_to_share

  searchable do
    integer :byte_size
    time :access_time, :change_time, :modification_time, :created_at, :updated_at
    text :path do
      share_rel_path
    end
  end

  def self.searchable_ids
    {
      path: self.respond_to?(:path) && self.path
    }
  end

  def path_resolved?
    path == resolved_path
  end

  def resolve_path!
    unless path_resolved?
#      save! if new_record?
      resolve_path
      save!
    end
  end

  def resolved_path
    share.fs_path(::Playful::PathResolver::default_path_for_file(self))
  end

  def file_name
    File.basename(path)
  end

  def scan_and_update
    scanner = Playful::Factory.file_scanner
    scan = scanner.scan_file(path)
    update_from_scan(scan)
  end

  def update_from_scan(scan)
    if new_record?
      self.path = File.absolute_path(scan[:path])
      self.file_type = FileType.find_by_scan_type(scan[:conclusion])
    end
    self.byte_size = scan[:size]
    self.uid = scan[:stat][:uid]
    self.gid = scan[:stat][:gid]
    self.links = scan[:stat][:nlink]
    self.block_size = scan[:stat][:blksize]
    self.blocks = scan[:stat][:blocks]
    self.access_time = scan[:stat][:atime]
    self.change_time = scan[:stat][:ctime]
    self.modification_time = scan[:stat][:mtime]
  end

  def share_rel_path
    share.to_share_rel_path(path)
  end

  protected

  def resolve_path(overwrite = false, create_missing_dirs = true)
    unless path_resolved?
      if new_record?
        raise 'Cannot resolve non-persisted file'
      end

      new_path = resolved_path

      return if ::File.file?(new_path) && !overwrite

      dirname = ::File.dirname(new_path)
      if !::File.directory?(dirname) && create_missing_dirs
        FileUtils.mkpath dirname
      end

      FileUtils.mv(path, new_path)
#      FileUtils.cp(path, new_path)
      self.path = new_path
    end
  end

  # validations

  def file_belongs_to_share
    unless share.nil? || new_record?
      share_path = File.absolute_path(share.path).downcase
      file_path = File.dirname(File.absolute_path(path)).downcase
      unless file_path.starts_with?(share_path) && share_path.length <= file_path.length
        errors.add('share', "File path '#{path}' not in share #{share.name} '#{share.path}'")
      end
    end
  end

  def file_exists
    errors.add('path', "No such file '#{path}'") if path.nil? || !File.file?(path)
  end

end

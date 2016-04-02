class Share < ActiveRecord::Base
  has_many :base_files

  validates_presence_of :name
  validate :path_exists, :path_exclusive

  def fs_path(relative_file_path)
    ::File.join(path, relative_file_path)
  end

  def ensure_dir(relative_dir_path)
    dirname = fs_path(relative_dir_path)
    unless ::File.directory?(dirname)
      FileUtils.mkpath dirname
    end
  end

  def to_share_rel_path(absolute_file_path)
    absolute_file_path.gsub(/^#{path}\/?/i, "/#{name}/")
  end

  def to_fs_path(share_rel_path)
    fs_path(share_rel_path.gsub(/^\/?#{name}\/?/i, ''))
  end

  def belongs_to_share(file_path)
    /^#{path}/i =~ file_path || /^\/?#{name}\//i =~ file_path
  end

  def self.get_from_abs_path(absolute_file_path)
    Share.all.find {|s| /^#{s.path}/i =~ absolute_file_path }
  end

  def self.find_share_by_share_rel_path(share_rel_path)
    name_in_path = share_rel_path.split("/").compact.reject {|s| s.empty? }.first
    Share.find_by_name(name_in_path)
  end

  def self.find_share_by_fs_path(absolute_file_path)
    Share.all.find { |s| absolute_file_path.downcase.start_with?(s.path.downcase) }
  end

  private

  def path_exists
    errors.add('path', "no such directory #{path}") unless !path.nil? && File.directory?(path)
  end

  def path_exclusive
    share_paths = Share.all.map(&:path)
    collisions = share_paths.select {|sp| sp.gsub(/^#{path}\/?/i, '').length == 0 || path.gsub(/^#{sp}\/?/i, '').length == 0 }
    unless collisions.empty?
      errors.add('path', "Shares must be mutually exclusive. #{path} collides with #{collisions.inspect}")
    end
  end
end

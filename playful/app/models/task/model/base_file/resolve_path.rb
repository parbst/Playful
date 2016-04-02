class Task::Model::BaseFile::ResolvePath < Task::Model::BaseFile

  validates :base_file_id, presence: true

  TYPE = "baseFileResolvePathTask"

  def execute
    base_file.resolve_path!
  end

end

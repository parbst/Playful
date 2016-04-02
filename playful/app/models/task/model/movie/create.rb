class Task::Model::Movie::Create < Task::Model::Movie

  validate :has_video_files_or_imports

  TYPE = 'movieImportTask'

  def execute
    add_update_and_save
    super()
  end

  private

  def has_video_files_or_imports
    if dependee_by_class(Task::Model::BaseFile::VideoFile::Create).empty? && !video_file_ids.kind_of?(Array)
      errors.add('video_file_ids', 'No video file or video file import associated with movie import')
    end
  end

end

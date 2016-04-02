class Task::Model::BaseFile::VideoFile::Delete < Task::Model::BaseFile::Delete

  TYPE = "videoDeleteTask"
  def model(m_id = model_id, m_type = model_type)
    super(m_id, ::BaseFile::VideoFile.to_s)
  end

end

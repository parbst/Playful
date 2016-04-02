class Task::Model::BaseFile::AudioFile::Delete < Task::Model::BaseFile::Delete

  TYPE = "audioDeleteTask"
  def model(m_id = model_id, m_type = model_type)
    super(m_id, ::BaseFile::AudioFile.to_s)
  end

end

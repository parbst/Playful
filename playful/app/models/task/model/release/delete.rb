class Task::Model::Release::Delete < Task::Model::Delete

  TYPE = 'releaseDeleteTask'
  def model(m_id = model_id, m_type = model_type)
    super(m_id, ::Release.to_s)
  end

end

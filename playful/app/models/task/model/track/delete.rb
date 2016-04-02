class Task::Model::Track::Delete < Task::Model::Delete

  TYPE = 'trackDeleteTask'
  def model(m_id = model_id, m_type = model_type)
    super(m_id, ::Track.to_s)
  end

end
class Task::Model::Season::Change < Task::Model::Season

  validate :season_exists

  TYPE = 'seasonChangeTask'
  def execute
    @model = model
    update_model
    super
  end

  def model(m_id = model_id, m_type = model_type)
    if m_id.nil? && !season_number.nil?
      ::Season.find_by_season_number(season_number)
    else
      super(m_if, m_type)
    end
  end

  def season_exists
    if model_id.nil? && !::Season.find_by_season_number(season_number)
      errors.add('season', 'no season id given and not none with that season_number')
    end
  end

end
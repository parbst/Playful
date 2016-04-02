class Task::Model::Season::Delete < Task::Model::Delete

  store_accessor :model_store, [:season_number, :tv_series_id]

  validates :season_number, :tv_series_id, :presence => true
  validate :season_exists

  TYPE = 'seasonDeleteTask'

  def model(m_id = model_id, m_type = model_type)
    if !m_id.nil? && !m_type.nil?
      super
    else
      if tv_series_id.nil?
        tv_series = dependee_by_name(:tv_series_task).model
      else
        tv_series = ::TvSeries.find(tv_series_id)
      end
      tv_series.seasons.where(season_number: season_number).first
    end
  end

  def season_exists
    if !(completed? || failed?) && model.nil?
      errors.add('season', "season to be deleted doesn't exist")
    end
  end

  def setup
    super
    @valid_task_dependees[:tv_series_task] = Task::Model::TvSeries::Change
  end
end
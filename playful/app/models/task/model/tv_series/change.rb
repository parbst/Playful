class Task::Model::TvSeries::Change < Task::Model::TvSeries

  TYPE = 'tvSeriesChangeTask'
  def execute
    @model = model
    update_model
    super
  end

end
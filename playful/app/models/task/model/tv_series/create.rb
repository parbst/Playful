class Task::Model::TvSeries::Create < Task::Model::TvSeries

  TYPE = 'tvSeriesImportTask'
  def execute
    add_update_and_save
    super()
  end

end
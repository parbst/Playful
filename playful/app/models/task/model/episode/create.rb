class Task::Model::Episode::Create < Task::Model::Episode

  TYPE = 'episodeImportTask'
  def execute
    @model = ::Episode.new
    set_tv_series
    set_season
    add_update_and_save
    super()
  end

end
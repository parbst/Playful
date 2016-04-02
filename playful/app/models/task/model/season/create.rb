class Task::Model::Season::Create < Task::Model::Season

  TYPE = 'seasonImportTask'
  def execute
    @model = ::Season.new
    set_tv_series
    add_update_and_save
    super()
  end

end
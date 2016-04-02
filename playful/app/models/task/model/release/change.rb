class Task::Model::Release::Change < Task::Model::Release

  TYPE = 'releaseChangeTask'
  def execute
    @model = model
    update_model
    save_model
    super()
  end

end

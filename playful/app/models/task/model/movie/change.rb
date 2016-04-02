class Task::Model::Movie::Change < Task::Model::Movie

  TYPE = 'movieChangeTask'

  def execute
    @model = model
    update_model(true)
    super()
    detach_video_clips
  end

end

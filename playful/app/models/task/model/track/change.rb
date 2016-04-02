class Task::Model::Track::Change < Task::Model::Track

  TYPE = 'trackChangeTask'
  def execute
    @model = model
    update_model(true)
    save_model
    super()
    detach_audio_clips
  end

end
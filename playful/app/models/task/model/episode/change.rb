class Task::Model::Episode::Change < Task::Model::Episode

  TYPE = 'episodeChangeTask'
  def execute
    @model = model
    update_model
    update_video_clips
    super
    detach_video_clips
  end

end
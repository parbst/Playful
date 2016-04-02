class Task::Model::Track::TagAndResolve < Task::Model::Track

  TYPE = 'trackTagAndResolveTask'
  def execute
    @model = model
    @model.audio_files.select {|af| af.reference_track == @model }.each do |af|
      af.update_from_relations
      af.save!
    end
  end

  def setup
    super()
    @valid_task_dependees[:track_task] = Task::Model::Track
  end

end

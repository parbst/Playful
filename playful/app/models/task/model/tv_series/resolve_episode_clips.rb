class Task::Model::TvSeries::ResolveEpisodeClips < Task::Model::TvSeries

  TYPE = 'tvSeriesResolveEpisodeClipsTask'
  def execute
    @model = model
    @model.seasons.each do |s|
      s.episodes.each(&:resolve_clips)
    end
  end

  def model
    model_alt_id_or_input_task(:input_task, :tv_series_id, 'TvSeries')
  end

  def setup
    super
    @valid_task_dependees[:input_task] = Task::Model::TvSeries
  end

end
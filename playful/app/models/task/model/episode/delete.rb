class Task::Model::Episode::Delete < Task::Model::Delete

  store_accessor :model_store, [:season_number, :tv_series_id, :episode_number]

  validates :season_number, :tv_series_id, :presence => true
  validate :season_exists

  TYPE = 'episodeDeleteTask'
  def model(m_id = model_id, m_type = model_type)
    if tv_series_id.nil?
      tv_series = dependee_by_name(:tv_series_task).model
    else
      tv_series = ::TvSeries.find(tv_series_id)
    end
    season = tv_series.seasons.where(season_number: season_number).first
    season.episodes.find { |e| e.episode_number == episode_number }
  end

  def season_exists
    if !(completed? || failed?) && model.nil?
      errors.add('episode', "episode to be deleted doesn't exist")
    end
  end
end
class Task::Model::Episode < Task::Model

  include VideoAttachableTask
  include PosterAttachableTask

  def self.model_fields
    [:name, :description, :item_order, :poster_url, :poster_file_id, :air_date, :season_number,
     :tv_series_id, :season_id, :casts] + ::Episode.searchable_ids.keys
  end

  store_accessor :model_store, self.model_fields

  validate :season_exists
  validates :season_number, :episode_number, :presence => true

  def execute
    append_video_clips
    resolve_clips
    attach_poster_file
  end

  def retrieve
    scanner = Playful::Factory.metadata_scanner
    scan_result = scanner.tv_series_episode_lookup(@model.metadata_lookup_args)
    @model.update_from_metadata(scan_result, overwrite_with_nil = false) unless scan_result.nil?
  end

  def update_fields(overwrite = false)
    super(overwrite, self.class.model_fields - [:casts, :season_number, :season_id, :tv_series_id])
    @model.update_casts(self.casts)
  end

  def setup
    super()
    @valid_task_dependees[:tv_series_task] = Task::Model::TvSeries::Create
    @valid_task_dependees[:season_task] = Task::Model::Season::Create
    @valid_task_dependees[:poster_file_task] = Task::Model::BaseFile::ImageFile::Create
    @valid_task_dependees_dynamic << Task::Model::BaseFile::VideoFile::Create
  end

  def season_exists
    st = dependee_by_name(:season_task)
    if st.nil?
      # season must already exist
      season = ::Season.where({tv_series_id: tv_series_id, season_number: season_number}).first
      ok = !!season
    else
      st = dependee_by_name(:season_task)
      ok = st.season_number == season_number
    end

    unless ok
      errors.add(:season, 'Invalid season for episode. Either the season does not exist and was not included as a dependency')
    end
  end

  def set_tv_series
    unless @model.nil?
      tv_series_create_task = dependee_by_name(:tv_series_task)
      if !tv_series_create_task.nil?
        @model.tv_series = tv_series_create_task.model
      elsif !tv_series_id.nil?
        @model.tv_series = ::TvSeries.find(tv_series_id)
      end
    end
  end

  def set_season
    @model.season = get_season unless @model.nil?
  end

  def has_tv_series
    if tv_series_id.nil? && dependee_by_name(:tv_series_task).nil?
      errors.add(:tv_series_id, 'No tv series specified for episode. Provide either an id or a task to depend on')
    end
  end

  def model(m_id = model_id, m_type = model_type)
    if !m_id.nil? && !m_type.nil?
      super
    else
      season = get_season
      season.episodes.find {|e| e.episode_number == episode_number }
    end
  end

  private

  def get_season
    season_create_task = dependee_by_name(:season_task)
    if !season_create_task.nil?
      season_create_task.model
    elsif !season_id.nil?
      ::Season.find(season_id)
    elsif !season_number.nil?
      ::Season.where({tv_series_id: tv_series_id, season_number: season_number}).first
    end
  end

end
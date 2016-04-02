class Task::Model::Season < Task::Model

  include PosterAttachableTask

  def self.model_fields
    [:name, :description, :poster_url, :poster_file_id, :tv_series_id, :air_date, :casts] +
        ::Season.searchable_ids.keys
  end

  store_accessor :model_store, self.model_fields

  def retrieve
    scanner = Playful::Factory.metadata_scanner
    scan_result = scanner.tv_series_season_lookup(@model.metadata_lookup_args)
    @model.update_from_metadata(scan_result, overwrite_with_nil = false) unless scan_result.nil?
  end

  def update_fields(overwrite = false)
    super(overwrite, self.class.model_fields - [:casts])
    @model.update_casts(self.casts)
  end

  def setup
    super()
    @valid_task_dependees[:tv_series_task] = Task::Model::TvSeries::Create
    @valid_task_dependees[:poster_file_task] = Task::Model::BaseFile::ImageFile::Create
  end

  def execute
    attach_poster_file
  end

  protected

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

  def has_tv_series
    if tv_series_id.nil? && dependee_by_name(:tv_series_task).nil?
      errors.add(:tv_series_id, 'No tv series specified for season. Provide either an id or a task to depend on')
    end
  end
end
class Task::Model::TvSeries < Task::Model

  include PosterAttachableTask

  def self.model_fields
    [:original_name, :description, :poster_url, :poster_file_id, :genres, :languages, :casts, :tv_series_id] + ::TvSeries.searchable_ids.keys
  end

  store_accessor :model_store, self.model_fields + [:poster_file_path]

  def execute
    attach_poster_file
  end

  def setup
    super()
    @valid_task_dependees[:poster_file_task] = Task::Model::BaseFile::ImageFile::Create
  end

  def retrieve
    scanner = Playful::Factory.metadata_scanner
    scan_result = scanner.tv_series_lookup(@model.metadata_lookup_args)
    @model.update_from_metadata(scan_result, overwrite_with_nil = false) unless scan_result.nil?
  end

  def update_fields(overwrite = false)
    super(overwrite, self.class.model_fields - [:languages, :genres, :casts, :tv_series_id])
    @model.update_languages(self.languages)
    @model.update_genres(self.genres)
    @model.update_casts(self.casts)
  end

  def model
    model_or_alt_id(:tv_series_id, 'TvSeries')
  end

end
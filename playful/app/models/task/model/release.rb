class Task::Model::Release < Task::Model

  include PosterAttachableTask

  def self.model_fields
    [:name, :description, :release_type, :spotify_id, :year, :artist, :front_cover_id, :back_cover_id, :track_total,
     :genre, :disc_total, :release_id, :poster_file_id, :is_compilation] + ::Release.searchable_ids.keys
  end

  store_accessor :model_store, self.model_fields

  def retrieve
    scanner = Playful::Factory.metadata_scanner
    scan_result = scanner.release_lookup(@model.metadata_lookup_args)
    @model.update_from_metadata(scan_result, overwrite_with_nil = false)
  end

  def update_attributes_from_params(params)
    params[:release_id] = params[:id] unless params[:id].nil?
    super(params)
  end

  def update_fields(overwrite = false)
    super(overwrite, self.class.model_fields - [:release_id])
    max_disc_number = (dependent_by_class(Task::Model::Track).map { |t| t.disc_number } + @model.tracks.map { |t| t.disc_number }).max
    @model.disc_total = max_disc_number
  end

  def setup
    super()
    @valid_task_dependees[:front_cover_task] = Task::Model::BaseFile::ImageFile::Create
    @valid_task_dependees[:back_cover_task] = Task::Model::BaseFile::ImageFile::Create
    @valid_task_dependees[:release_task] = Task::Model::Release
  end

  def execute
    attach_poster_file({front_cover: :front_cover_task, back_cover: :back_cover_task })
  end

  def model
    model_alt_id_or_input_task(:release_task, :release_id, 'Release')
  end

end
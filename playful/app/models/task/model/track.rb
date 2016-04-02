class Task::Model::Track < Task::Model

  include AudioAttachableTask

  def self.model_fields
    [:title, :artist, :composer, :spotify_id, :year, :disc_number, :comment, :track_number, :release_id, :track_id]
  end

  store_accessor :model_store, self.model_fields + [:primary_audio_file_id]

  def update_fields(overwrite = false)
    super(overwrite, self.class.model_fields - [:track_id])
  end

  def update_attributes_from_params(params)
    params[:track_id] = params[:id] unless params[:id].nil?
    super(params)
  end

  def setup
    super()
    @valid_task_dependees[:release_task] = Task::Model::Release
    @valid_task_dependees[:track_task] = Task::Model::Track
    @valid_task_dependees[:primary_audio_file_task] = Task::Model::BaseFile::AudioFile::Create
    @valid_task_dependees_dynamic << Task::Model::BaseFile::AudioFile::Create
  end

  def execute
    set_release
    append_audio_clips
    resolve_clips
  end

  def set_release
    unless @model.nil?
      release_create_task = dependee_by_name(:release_task)
      if !release_create_task.nil?
        @model.release = release_create_task.model
      elsif !release_id.nil?
        @model.release = Release.find(release_id)
      end
    end
  end

  def ensure_defaults
    super()
    self.should_retrieve = false
  end

  def model
    model_alt_id_or_input_task(:track_task, :track_id, 'Track')
  end

end
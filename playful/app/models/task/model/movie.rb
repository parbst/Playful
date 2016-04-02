class Task::Model::Movie < Task::Model

  include VideoAttachableTask
  include PosterAttachableTask

  def self.model_fields
    [:release_date, :original_title, :tagline, :storyline, :youtube_trailer_source,
     :poster_url, :languages, :genres, :casts, :poster_file_id, :movie_id] + ::Movie.searchable_ids.keys
  end

  store_accessor :model_store, self.model_fields

  validate :valid_input

  def retrieve
    scanner = Playful::Factory.metadata_scanner
    scan_result = scanner.movie_lookup(metadata_scanner_args).first
    @model.update_from_metadata(scan_result, overwrite_with_nil = false)
  end

  def execute
    append_video_clips
    resolve_clips
    attach_poster_file
  end

  def model
    result = self.model_id.nil? ? nil : super

    if !result && !movie_id.nil?
      result = super(movie_id, 'Movie')
    end

    result
  end

  protected

  def setup
    super()
    @valid_task_dependees_dynamic << Task::Model::BaseFile::VideoFile::Create
    @valid_task_dependees[:poster_file_task] = Task::Model::BaseFile::ImageFile::Create
  end

  private

  def update_fields(overwrite = true)
    super(overwrite, self.class.model_fields - [:languages, :genres, :casts, :movie_id])
    @model.update_languages(self.languages)
    @model.update_genres(self.genres)
    @model.update_casts(self.casts)
  end

  def metadata_scanner_args
    {}.tap do |o|
      o[:tmdb] = { movie_id: @model.tmdb_id } unless @model.tmdb_id.nil?
      o[:text] = { movie_title: @model.title } unless @model.title.nil?
    end
  end

  def valid_input
    valid_genres = !genres.is_a?(Hash) || genres[:add].is_a?(Array) && genres[:add].all? { |g| Genre.valid_creation_data? g }
    valid_languages = !languages.is_a?(Hash) || languages[:add].is_a?(Array) && languages[:add].all? { |l| Language.valid_creation_data? l }
    valid_casts = !casts.is_a?(Hash) || !casts[:add].is_a?(Array) || casts[:add].all? { |a| Actor.valid_creation_data? a }
    errors.add('languages', "At least one language did not have the correct keys/types #{languages.inspect}") unless valid_languages
    errors.add('genres', "At least one genre did not have the correct keys/types #{genres.inspect}") unless valid_genres
    errors.add('casts', "At least one actor did not have the correct keys/types #{casts.inspect}") unless valid_casts
  end
end

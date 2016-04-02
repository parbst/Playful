require 'active_support/concern'

module AudioAttachableTask
  extend ActiveSupport::Concern

  included do
    store :store_audio_clip, accessors: [:audio_file_ids, :primary_audio_file_ids, :audio_file_delete_ids]
    validate :valid_audio_files
  end

  def append_audio_clips
    import_tasks = dependee_by_class(Task::Model::BaseFile::AudioFile::Create).uniq # because primary audio file can be added twice
    audio_files = import_tasks.map { |t| t.model }
    audio_files += ::BaseFile::AudioFile.find(audio_file_ids) unless audio_file_ids.nil?

    audio_clips = audio_files.map{ |af| AudioClip.ensure(audio_file: af, set: 1, model: @model) }.compact
#    primary_clips_from_ids = Array(primary_audio_file_ids).map {|af_id| audio_clips.find {|ac| ac.audio_file.id == af_id } }
#    clips_from_import_tasks = import_tasks.map {|it| audio_clips.find {|ac| ac.audio_file.id == it.model.id }}

    (Array(primary_audio_file_ids).map {|af_id| audio_clips.find {|ac| ac.audio_file.id == af_id } } +
        import_tasks.map {|it| audio_clips.find {|ac| ac.audio_file.id == it.model.id }}).compact.each do |ac|
      ac.audio_file.audio_clips.where(primary_track: true).each {|ac2| ac2.primary_track = false; ac2.save! }
      ac.primary_track = true
    end
    audio_clips.select {|ac| ac.new_record? || ac.changed? }.each(&:save!)
    @model.audio_clips += audio_clips

    @model.save!

    @model.audio_clips.sort_by {|ac| ac.primary_track ? 1 : -1; }.map(&:audio_file).each do |af|
      af.update_from_relations if af.reference_track == @model
      af.save!
    end
  end

  def resolve_clips
    @model.audio_clips.sort_by {|ac| ac.primary_track ? 1 : -1 }.map(&:audio_file).each(&:resolve_path!)
  end

  def add_audio_clip_attachment(audio_info, audio_import_task = nil)
    self.audio_file_ids ||= []
    self.primary_audio_file_ids ||= []


    if audio_info.is_a?(Integer)
      self.audio_file_ids << video_info
    elsif audio_info.is_a?(Hash)
      if audio_info[:audio_file_id]
        # audio file already exists, just append to the track task
        self.primary_audio_file_ids << audio_info[:audio_file_id] if audio_info[:primary_track]
        self.audio_file_ids << audio_info[:audio_file_id]
      else
        unless audio_import_task.is_a?(Task::Model::BaseFile::AudioFile)
          raise 'cannot add_audio_clip_attachment without an audio file id or an audio file import task'
        end
        depend_on(audio_import_task)
      end
    elsif audio_info.is_a?(Array)
      audio_info.each {|ai| add_audio_clip_attachment(ai) }
    end
  end

  def detach_audio_clips
    unless audio_file_delete_ids.nil?
      @model.audio_clips.select {|ac| audio_file_delete_ids.include?(ac.audio_file.id) }.each(&:destroy)
    end
  end

  def valid_audio_files
    unless audio_file_ids.nil? || audio_file_ids.all? { |id| ::BaseFile::AudioFile.exists?(id) }
      errors.add('audio_file_ids', "Non-existing audio file #{audio_file_ids.inspect}")
    end
  end

end

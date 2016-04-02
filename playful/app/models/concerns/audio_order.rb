require 'active_support/concern'
require 'task/model/release/create.rb' # this is so weird but necessary

module AudioOrder
  extend ActiveSupport::Concern

  module ClassMethods

    def create_import_from_params(params)
      validate_creation_params(params)

      # create / change release
      # create audio file
      # create / change track
      # update tracks
      # tag_and_resolve

      tasks = []
      import_share = Share.where(id: params[:import_share_id]).first
      tasks += create_track_tasks(params[:tracks], nil, false, import_share) unless params[:tracks].nil?
      tasks += create_release_tasks_for_create(params[:releases], import_share) if params[:releases]
      tasks
    end

    def create_release_tasks_for_create(releases_params, import_share)
      tasks = []
      releases_params.each do |release_params|
        release_class = release_params[:id].nil? ? Task::Model::Release::Create : Task::Model::Release::Change
        tasks << release_task = release_class.create_from_params(release_params)
        track_tasks = []
        tasks += track_tasks = create_track_tasks(release_params[:tracks], release_task, release_params[:update_from_metadata], import_share) unless release_params[:tracks].nil?
        if release_params[:update_from_metadata]
          tasks << update_tracks_task = Task::Model::Release::UpdateTracks.new
          update_tracks_task.depend_on(release_task: release_task)

          # ensure that validation will pass, as the actual values will be updated later from metadata (or fail the order)
          if release_class.is_a?(Task::Model::Release::Create)
            release_class.release_type = 'Album' if release_class.release_type.blank?
            release_class.artist = 'placeholder for validation' if release_class.artist.blank?
            release_class.title = 'placeholder for validation' if release_class.title.blank?
          end
          track_tasks.select { |t| t.is_a?(Task::Model::Track::Create)}.each do |tt|
            # TODO: this is wrong. even tough the update tracks task is the most convenient it is bad for correctness to postpone data fetch until after the file has been added to the db
            tt.title = 'placeholder for validation' if tt.title.blank?
            tt.artist = 'placeholder for validation' if tt.artist.blank?
          end
        end
        unless release_params[:tracks].nil?
          tasks += (track_tasks || []).select { |tt| tt.is_a?(Task::Model::Track) }
          .map { |tt| Task::Model::Track::TagAndResolve.new.depend_on(track_task: tt) }
        end

        if release_params[:front_cover_file_path]
          share = Share.find(release_params[:share_id])
          tasks << font_cover_task = Task::Model::BaseFile::ImageFile::Create(path: import_share.to_fs_path(release_params[:front_cover_file_path]), share: share)
          release_class.depend_on(front_cover_task: font_cover_task)
        end
        if release_params[:back_cover_file_path]
          share ||= Share.find(release_params[:share_id])
          tasks << font_cover_task = Task::Model::BaseFile::ImageFile::Create(path: import_share.to_fs_path(release_params[:back_cover_file_path]), share: share)
          release_class.depend_on(back_cover_task: font_cover_task)
        end
      end
      tasks
    end

    def create_change_from_params(params)
      validate_change_params(params)

      tasks = []

      tasks += create_track_tasks(params[:tracks][:change], nil, false, nil) if params[:tracks] && params[:tracks].has_key?(:change)
      if params[:tracks] && params[:tracks].has_key?(:delete)
        tasks += params[:tracks][:delete].map { |track_id| Task::Model::Track::Delete.create(model_id: track_id) }
      end

      tasks += create_release_tasks_for_change(params[:releases][:change]) if params[:releases] && params[:releases].has_key?(:change)
      if params[:releases] && params[:releases].has_key?(:delete)
        tasks += params[:releases][:delete].map { |release_id| Task::Model::Release::Delete.create(model_id: release_id) }
      end

      if params[:audio_files] && params[:audio_files].has_key?(:delete)
        tasks += create_audio_file_delete_tasks(params[:audio_files][:delete])
      end

      changed_track_ids = tasks.map do |t|
        if t.is_a?(Task::Model::Track::Change)
          [t.track_id]
        elsif t.is_a?(Task::Model::Release::Change)
          Release.find(t.release_id).tracks.map(&:id)
        else
          []
        end
      end.flatten

      tasks += changed_track_ids.map{ |id| Task::Model::Track::TagAndResolve.new(track_id: id ) }

      tasks
    end

    def create_release_tasks_for_change(releases_params)
      tasks = []
      releases_params.each do |release_params|
        tasks << release_task = Task::Model::Release::Change.create_from_params(release_params)
        if release_params[:update_from_metadata]
          release_task.should_retrieve = true
          tasks << Task::Model::Release::UpdateTracks.new.depend_on(release_task: release_task)
        end
      end
      tasks
    end

    def create_audio_file_delete_tasks(base_file_ids)
      base_file_ids.map {|base_file_id| Task::Model::BaseFile::AudioFile::Delete.create(model_id: base_file_id)}
    end

    def create_track_tasks(tracks_params, release_task, update_from_metadata, import_share)
      result = []

      tracks_params.each do |track_params|
        track_task = (track_params[:id].nil? ? Task::Model::Track::Create : Task::Model::Track::Change).create_from_params(track_params)
        track_task.depend_on(:release_task => release_task) unless release_task.nil?
        unless track_params[:audio_files].nil?
          result += create_audio_file_tasks(track_params[:audio_files], track_task, update_from_metadata, import_share)
        end
        if track_params.has_key?(:audio_clips)
          audio_clips = track_params[:audio_clips]
          add_video_clips = []

          if audio_clips.is_a?(Array)
            add_video_clips = audio_clips
          elsif audio_clips.is_a?(Hash)
            add_video_clips = audio_clips[:add] if audio_clips.has_key?(:add)
            if audio_clips.has_key?(:delete)
              track_task.audio_file_delete_ids = audio_clips[:delete]
            end
          end

          unless add_video_clips.empty?
            track_task.audio_file_ids = add_video_clips.map{ |t| t[:audio_file_id] }.compact
            track_task.primary_audio_file_ids = add_video_clips.select{ |t| t[:primary_track] }.pluck(:audio_file_id).compact
          end
        end
        result << track_task
      end

      result
    end

    def create_audio_file_tasks(audio_files_params, track_task, update_from_metadata, import_share)
      result = []
      audio_files_params.each do |audio_file_param|
        audio_file_import_task = nil
        unless audio_file_param[:audio_file_id]
          share = Share.find(audio_file_param[:share_id])
          file_fs_path = import_share.to_fs_path(audio_file_param[:audio_file_path])
          audio_file_import_task = Task::Model::BaseFile::AudioFile::Create.new(:share => share, :path => file_fs_path)
          result << audio_file_import_task
        end
        track_task.add_audio_clip_attachment(audio_file_param, audio_file_import_task)
      end
      result
    end

    def validate_creation_params(params)
      params_shape = {
        order_type:                 String,
        import_share_id:            Integer,
        tracks: [
          {
            id:                     Integer,
            artist:                 String,
            composer:               String,
            title:                  String,
            track_number:           Integer,
            disc_number:            Integer,
            comment:                String,
            year:                   Integer,
            audio_files: [
              {
                audio_file_id:      Integer,
                audio_file_path:    String,
                primary_track:      Boolean,
                share_id:           Integer
              }
            ]
          }
        ],
        releases: [
          {
            update_from_metadata:   Boolean,
            id:                     Integer,
            artist:                 String,
            track_total:            Integer,
            genre:                  String,
            disc_total:             Integer,
            is_compilation:         Boolean,
            front_cover_file_path:  String,
            front_cover_file_id:    String,
            back_cover_file_path:   String,
            back_cover_file_id:     String,
            share_id:               Integer,
            spotify_id:             String,
            tracks: []
          }
        ]
      }.tap do |o|
        o[:releases][0][:tracks] << o[:tracks].first
      end

      params.convert_to_shape!(params_shape)
      shape_opts = { allow_undefined_keys: true, allow_missing_keys: true, allow_nil_values: true, error_on_mismatch: true }
      params.has_shape?(params_shape, shape_opts)

      import_share = Share.find_by_id(params[:import_share_id])

      if params.is_a?(Hash)
        if params[:tracks]
          params[:tracks].each {|t| validate_track_create(t, false, import_share) }
        end
        if params[:releases]
          params[:releases].each {|r| validate_release_create(r, import_share) }
        end
      end
    end

    def validate_change_params(params)
      params_shape = {
        order_type:                   String,
        tracks: {
          change: [
            {
              id:                     Integer,
              artist:                 String,
              composer:               String,
              title:                  String,
              track_number:           Integer,
              disc_number:            Integer,
              comment:                String,
              year:                   Integer,
              audio_clips: {
                add: [
                  {
                    audio_file_id:    Integer,
                    primary_track:    Boolean,
                  }
                ],
                delete: [
                  Integer # audio_file_ids
                ]
              }
            }
          ],
          delete: [
            Integer # track_ids
          ]
        },
        releases: {
          change: [
            {
              update_from_metadata:   Boolean,
              id:                     Integer,
              artist:                 String,
              track_total:            Integer,
              genre:                  String,
              disc_total:             Integer,
              is_compilation:         Boolean,
              front_cover_file_id:    String,
              back_cover_file_id:     String,
              spotify_id:             String
            }
          ],
          delete: [
              Integer # release_ids
          ]
        },
        audio_files: {
          delete: [
              Integer # audio_file_ids
          ]
        }
      }

      params.convert_to_shape!(params_shape)
      shape_opts = { allow_undefined_keys: true, allow_missing_keys: true, allow_nil_values: true, error_on_mismatch: true }
      params.has_shape?(params_shape, shape_opts)

      if params.is_a?(Hash)
        if params[:tracks] && params[:tracks].has_key?(:change)
          params[:tracks][:change].each {|t| validate_track_change(t) }
        end
        if params[:releases] && params[:releases].has_key?(:change)
          params[:releases][:change].each {|r| validate_release_change(r) }
        end
      end
    end

    def validate_track_change(track)
      validate_track(track)
      if track[:audio_clips].is_a?(Hash)
        if track[:audio_clips].has_key?(:add) && !track[:audio_clips][:add].all? {|ac| ac.is_a?(Hash) && ac.has_key?(:audio_file_id)}
          raise Order::OrderValidationError.new "Invalid audio clip section #{track[:audio_clips].inspect}. audio clips added refer to an id"
        end
      end

      unless track.has_key?(:id)
        raise Order::OrderValidationError.new "Invalid audio track data #{track.inspect}. Must provide track id when changing a track."
      end
    end

    def validate_track_create(track, in_release, import_share = nil)
      validate_track(track, in_release)
      track[:audio_files].each { |af| validate_audio_clip(af, import_share) } if track[:audio_files]
    end

    def validate_track(track, in_release = false)
      unless track.has_key?(:id) ||
               (track.has_key?(:title) && track.has_key?(:artist) ||
                in_release && track.has_key?(:track_number) && track.has_key?(:disc_number))
        raise Order::OrderValidationError.new "Invalid audio track data #{track.inspect}. Must have either id or title and either artist or track number and disc number if the track belongs to a release"
      end
    end

    def validate_release_change(release)
      validate_release(release)
      unless release.has_key?(:id)
        raise Order::OrderValidationError.new "Invalid audio release data #{release.inspect}. Must provide release id when changing a release."
      end
    end

    def validate_release_create(release, import_share)
      validate_release(release)
      release[:tracks].each { |t| validate_track_create(t, true, import_share) } if release[:tracks]
      if (release.has_key?(:front_cover_file_path) || release.has_key?(:back_cover_file_path)) && !release.has_key?(:share_id)
        raise Order::OrderValidationError.new "Cannot import cover files without a share_id"
      end
      if release.has_key?(:back_cover_file_path)
        if import_share.nil?
          raise Order::OrderValidationError.new "Importing files but not providing an import share"
        end
        if !import_share.belongs_to_share(release[:back_cover_file_path])
          raise Order::OrderValidationError.new "Imported file #{release[:back_cover_file_path]} did not belong to import share"
        end
      end
    end

    def validate_release(release)
      unless release.has_key?(:id) || Release.valid_creation_data?(release)
        raise Order::OrderValidationError.new "Invalid audio release data #{release.inspect}. Must a least have an artist specified or be a compilation"
      end
    end

    def validate_audio_clip(audio_clip, import_share)
      unless audio_clip.has_key?(:audio_file_id) || audio_clip.has_key?(:audio_file_path) && audio_clip.has_key?(:share_id)
        raise Order::OrderValidationError.new "Invalid audio clip data #{audio_clip.inspect}. Must a least have an artist specified or be a compilation"
      end
      if audio_clip.has_key?(:audio_file_path)
        unless audio_clip[:primary_track]
          raise Order::OrderValidationError.new "Invalid audio clip data #{audio_clip.inspect}. A newly imported audio file must have the associated track as primary"
        end
        if import_share.nil?
          raise Order::OrderValidationError.new "Importing files but not providing an import share id"
        end
        unless import_share.belongs_to_share(audio_clip[:audio_file_path])
          raise Order::OrderValidationError.new "Imported file #{audio_clip[:audio_file_path]} did not belong to import share"
        end
      end
    end
  end

end
require 'active_support/concern'

module TvSeriesOrder
  extend ActiveSupport::Concern

  class ValidationError < StandardError ; end

  module ClassMethods
=begin
    import order
    {
      update_from_metadata: boolean
      tv_series: <tv series values without delete and change>
    }
=end
    def order_params_shape
      {
        tv_series: {
          update_from_metadata: Boolean,
          name:                 String,
          original_name:        String,
          description:          String,
          poster_url:           String,
          poster_file_id:       Integer,
          poster_file_path:     String,
          poster_file_share_id: Integer,
          tmdb_id:              Integer,
          imdb_id:              String,
          freebase_id:          String,
          tv_series_id:         Integer,
          genres: {
            add: [
              {
                name:             String,
                tmdb_id:          Integer
              }
            ],
            delete: [
              {
                name:             String,
                tmdb_id:          Integer
              }
            ]
          },
          languages: {
            add: [
              {
                name:             String,
                iso_639_1:        String
              }
            ],
            delete: [
              {
                name:             String,
                iso_639_1:        String
              }
            ]
          },
          seasons: {
            add:    [],         # season values
            delete: [{
              season_number:    Integer
            }],
            change: []          # season values
          },
          episodes: {
            add: [],            # episode values
            delete: [
              {
                episode_number: Integer,
                season_number:  Integer
              }
            ],
            change: []          # episode values
          },
          video_clips: {
            add: [],            # video clip values
            delete: [{
              season_number:      Integer,
              episode_number:     Integer,
              video_file_id:      Integer,
              delete_video_file:  Boolean
            }],
            change: []          # video clip values
          }
        }
      }.tap do |o|
        season_values = {
          update_from_metadata: Boolean,
          name:                 String,
          description:          String,
          poster_url:           String,
          poster_file_id:       Integer,
          poster_file_path:     String,
          freebase_id:          String,
          tmdb_id:              Integer,
          air_date:             Date,
          season_number:        Integer
        }
        episode_values = {
          update_from_metadata: Boolean,
          name:                 String,
          description:          String,
          order:                Integer,
          air_date:             Date,
          poster_url:           String,
          poster_file_id:       Integer,
          poster_file_path:     String,
          episode_number:       Integer,
          season_number:        Integer,
          tv_series_id:         Integer,
          tmdb_id:              Integer,
          freebase_id:          String,
          imdb_id:              String
        }
        video_clip_values = {
          season_number:    Integer,
          episode_number:   Integer,
          set:              Integer,
          order:            Integer,
          video_file_id:    Integer,
          path:             String,
          share_id:         Integer
        }
        casts_values = {
            add: [
                {
                    actor_name:           String,
                    actor_image_url:      String,
                    character_name:       String,
                    character_image_url:  String,
                    order:                Integer
                }
            ],
            change: [
                {
                    character_name:       String,
                    character_image_url:  String,
                    order:                Integer
                }
            ],
            delete: [
                {
                    character_name:       String
                }
            ]
        }
        episode_values[:casts] = casts_values
        season_values[:casts] = casts_values
        o[:tv_series][:casts] = casts_values
        o[:tv_series][:seasons][:add] << season_values
        o[:tv_series][:seasons][:change] << season_values
        o[:tv_series][:episodes][:add] << episode_values
        o[:tv_series][:episodes][:change] << episode_values
        o[:tv_series][:video_clips][:add] << video_clip_values
        o[:tv_series][:video_clips][:change] << video_clip_values
      end
    end

    # TODO: make import shares on movies and tv series aswell
    def validate_import_input(params)
      params.convert_to_shape!(order_params_shape)
      shape_opts = { allow_undefined_keys: true, allow_missing_keys: true, allow_nil_values: true, error_on_mismatch: true }
      params.has_shape?(order_params_shape, shape_opts)
      validate_tv_series_input(params[:tv_series], true)
    end

    def create_tasks(params, main_task_type = Task::Model::TvSeries::Create)
      result = []
      tv_series = params[:tv_series]
      unless tv_series.nil?
        tv_series_task = main_task_type.create_from_params(tv_series)
        if tv_series[:poster_file_path]
          share = Share.find(tv_series[:poster_file_share_id])
          import_poster_task = Task::Model::BaseFile::ImageFile::Create.new(:share => share, :path => tv_series[:poster_file_path])
          result << import_poster_task
          tv_series_task.depend_on(:poster_file_task => import_poster_task)
        end
        result << tv_series_task

        result += season_tasks = create_seasons_tasks(tv_series[:seasons])
        result += video_file_tasks = create_video_file_tasks(tv_series[:video_clips])
        result += episode_tasks = create_episodes_tasks(tv_series[:episodes], tv_series[:video_clips], video_file_tasks)

        tv_series_create_task = result.select { |t| t.is_a?(Task::Model::TvSeries::Create) }.first

        # attach episodes and seasons to the tv series
        result.select {|t| t.is_a?(Task::Model::Season) ||
                           t.is_a?(Task::Model::Episode) ||
                           t.is_a?(Task::Model::Season::Delete) ||
                           t.is_a?(Task::Model::Episode::Delete)}.each do |t|
          unless tv_series_create_task.nil?
            t.depend_on(:tv_series_task => tv_series_create_task)
          end
          t.tv_series_id = tv_series[:tv_series_id]
        end

        # attach seasons to the episodes
        season_tasks.each do |s|
          episode_tasks.select {|et| et.season_number == s.season_number }.each do |e|
            e.depend_on(:season_task => s)
          end
        end

        result << Task::Model::TvSeries::ResolveEpisodeClips.new.depend_on(input_task: tv_series_task)

        tv_series_task.should_retrieve = !!tv_series[:update_from_metadata]
      end

      result
    end

    def create_seasons_tasks(seasons)
      result = []
      seasons ||= {}
      # :poster_file_path,
      unless seasons[:add].nil?
        result += seasons[:add].map { |s| Task::Model::Season::Create.create_from_params(s) }
      end
      unless seasons[:change].nil?
        result += seasons[:change].map { |s| Task::Model::Season::Change.create_from_params(s) }
      end
      unless  seasons[:delete].nil?
        result += seasons[:delete].map {|s| Task::Model::Season::Delete.new({season_number: s[:season_number]})}
      end
      result
    end

    def create_video_file_tasks(video_clips)
      create = []
      if video_clips.is_a?(Hash)
        video_clips.each do |action, clips|
          create += clips.select { |vc| vc[:video_file_id].nil? }.uniq {|vc| vc[:path]}
        end
      end

      create.map do |vc|
        share = Share.find(vc[:share_id])
        Task::Model::BaseFile::VideoFile::Create.new(share: share, path: vc[:path])
      end
    end

    def create_episodes_tasks(episodes, video_clips, video_file_tasks)
      episode_tasks = []
      episodes ||= {}

      unless episodes[:add].nil?
        episode_tasks += episodes[:add].map { |e| Task::Model::Episode::Create.create_from_params(e) }
      end

      unless episodes[:delete].nil?
        episode_tasks += episodes[:delete].map {|e| Task::Model::Episode::Delete.new({episode_number: e[:episode_number], season_number: e[:season_number]})}
      end

      unless episodes[:change].nil?
        episode_tasks += episodes[:change].map { |e| Task::Model::Episode::Change.create_from_params(e) }
      end

      if video_clips.is_a?(Hash)
        (Array(video_clips[:add]) + Array(video_clips[:change]) + Array(video_clips[:delete])).each do |vc|
          assoc_episode_task = episode_tasks.select { |et| et.season_number == vc[:season_number] && et.episode_number == vc[:episode_number] }.first
          if assoc_episode_task.nil?
            episode_tasks << Task::Model::Episode::Change.new(season_number: vc[:season_number],
                                                              episode_number: vc[:episode_number])
          end
        end

        Array(video_clips[:add]).each do |vc|
          assoc_episode_task = episode_tasks.select { |et| et.season_number == vc[:season_number] && et.episode_number == vc[:episode_number] }.first
          assoc_episode_task.add_video_clip_attachment(vc, video_file_tasks.find { |vft| vft.path == vc[:path] })
        end

        Array(video_clips[:change]).each do |vc|
          assoc_episode_task = episode_tasks.select { |et| et.season_number == vc[:season_number] && et.episode_number == vc[:episode_number] }.first
          assoc_episode_task.add_video_clip_change(vc)
        end

        Array(video_clips[:delete]).each do |vc|
          assoc_episode_task = episode_tasks.select { |et| et.season_number == vc[:season_number] && et.episode_number == vc[:episode_number] }.first
          assoc_episode_task.add_video_clip_deletion(vc[:video_file_id])
          if vc[:delete_video_file]
            episode_tasks << Task::Model::BaseFile::VideoFile::Delete.create(model_id: vc[:video_file_id])
          end
        end
      end

      episode_tasks
    end

    def validate_change_input(params)
      params.convert_to_shape!(order_params_shape)
      shape_opts = { allow_undefined_keys: true, allow_missing_keys: true, allow_nil_values: true, error_on_mismatch: true }
      params.has_shape?(order_params_shape, shape_opts)
      validate_tv_series_input(params[:tv_series], false)
    end

    def validate_tv_series_input(tv_series, is_import_order = false)
      order_specific_keys = [:poster_file_path, :genres, :languages, :seasons, :episodes, :video_clips]
      valid_model_data = TvSeries.valid_creation_data?(tv_series.except(*order_specific_keys))
      valid_genres = !tv_series[:genres].is_a?(Hash) || tv_series[:genres][:add].is_a?(Array) &&
              tv_series[:genres][:add].all? { |g| Genre.valid_creation_data? g }
      valid_languages = !tv_series[:languages].is_a?(Hash) || tv_series[:languages][:add].is_a?(Array) &&
              tv_series[:languages][:add].all? { |l| Language.valid_creation_data? l }

      if tv_series.has_key?(:poster_file_path) ^ tv_series.has_key?(:poster_file_share_id)
        raise TvSeriesOrder::ValidationError.new 'Must provide poster_file_path and poster_file_share_id together'
      end

      valid_seasons = true
      seasons = tv_series[:seasons]
      unless seasons.nil?
        if is_import_order && (seasons.has_key?(:delete) || seasons.has_key?(:change))
          raise TvSeriesOrder::ValidationError.new 'Invalid season data. Import order cannot specify delete or change requests'
        end

        valid_seasons =
            (!seasons.has_key?(:add) || seasons[:add].all? { |as| validate_season_input(as) }) &&
            (!seasons.has_key?(:change) || seasons[:change].all? { |cs| validate_season_input(cs) }) &&
            (!seasons.has_key?(:delete) || seasons[:delete].all? { |ds| ds.is_a?(Integer) })
      end

      valid_episodes = true
      episodes = tv_series[:episodes]
      unless episodes.nil?
        if is_import_order && (episodes.has_key?(:delete) || episodes.has_key?(:change))
          raise TvSeriesOrder::ValidationError.new 'Invalid episode data. Import order cannot specify delete or change requests'
        end

        valid_episodes =
            (!episodes.has_key?(:add) || episodes[:add].all? { |ae| validate_episode_input ae}) &&
            (!episodes.has_key?(:change) || episodes[:change].all? { |ce| validate_episode_input ce}) &&
            (!episodes.has_key?(:delete) || episodes[:delete].all? { |de| de.has_shape?({ episode_number: Integer, season_number: Integer }) })
      end

      valid_video_clips = true
      video_clips = tv_series[:video_clips]
      unless video_clips.nil?
        if is_import_order && (video_clips.has_key?(:delete) || video_clips.has_key?(:change))
          raise TvSeriesOrder::ValidationError.new 'Invalid video clips data. Import order cannot specify delete or change requests'
        end

        valid_video_clips =
            (!video_clips.has_key?(:add) || video_clips[:add].all? { |a_vc| validate_video_clip_input a_vc}) &&
            (!video_clips.has_key?(:change) ||
                # you may not change a video clip by uploading another video file for the clip
                (video_clips[:change].all? { |c_vc| validate_video_clip_input(c_vc) && c_vc.has_key?(:video_file_id) })) &&
            (!video_clips.has_key?(:delete) || video_clips[:delete].all? { |ds| ds.is_a?(Integer) })

        if is_import_order
          clips_has_associated_episode = video_clips[:add].all? do |vc|
            episodes[:add].any? {|e|
              e[:episode_number] == vc[:episode_number] && e[:season_number] == vc[:season_number]
            }
          end

          unless clips_has_associated_episode
            raise TvSeriesOrder::ValidationError.new 'Invalid video clips data. Added clips that did not have an associated episode'
          end
        end
      end

      if is_import_order
        if [:genres, :languages, :seasons, :episodes, :video_clips].any? {|k| tv_series.has_key?([k]) && tv_series[k].has_key?(:delete) }
          raise ValidationError.new "Tv Series import order cannot have any delete keys!"
        end
      end

      valid_model_data && valid_genres && valid_languages &&
          valid_seasons && valid_episodes && valid_video_clips
    end

    def validate_season_input(season)
      order_specific_shape = {
          :poster_file_path  => String
      }
      season.slice(*order_specific_shape.keys).has_shape?(order_specific_shape) &&
          Season.valid_creation_data?(season.except(*order_specific_shape.keys)) ||
          (raise TvSeriesOrder::ValidationError.new "Invalid season data #{season.inspect}" )
    end

    def validate_episode_input(episode)
      order_specific_shape = {
        :poster_file_path  => String,
        :season_number    => Integer
      }
      episode.slice(*order_specific_shape.keys).has_shape?(order_specific_shape) &&
          Episode.valid_creation_data?(episode.except(*order_specific_shape.keys)) ||
          (raise TvSeriesOrder::ValidationError.new "Invalid episode data #{episode.inspect}" )
    end

    def validate_video_clip_input(video_clip)
      order_specific_shape = {
          :path             => String,
          :id               => Integer,
          :season_number    => Integer,
          :episode_number   => Integer,
          :share_id         => Integer
      }
      video_clip.slice(*order_specific_shape.keys).has_shape?(order_specific_shape) &&
          VideoClip.valid_creation_data?(video_clip.except(*order_specific_shape.keys)) ||
          (raise TvSeriesOrder::ValidationError.new "Invalid video clip data #{video_clip.inspect}" )

      (video_clip.has_key?(:video_file_id) || video_clip.has_key?(:path) && video_clip.has_key?(:share_id)) ||
          (raise TvSeriesOrder::ValidationError.new "Video clips must have a share_id and either a path or a video_file_id #{video_clip.inspect}" )
    end
  end
end
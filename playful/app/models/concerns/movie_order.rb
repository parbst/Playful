require 'active_support/concern'

module MovieOrder
  extend ActiveSupport::Concern

  module ClassMethods
    def create_movie_tasks(movie_data)
      tasks = []

      movie_task = (movie_data[:movie_id].nil? ? Task::Model::Movie::Create : Task::Model::Movie::Change).create_from_params(movie_data)
      delete_video_files_tasks = []

      if movie_data[:video_clips].is_a?(Hash)
        if movie_data[:video_clips][:add].is_a?(Array)
          paths, ids = movie_data[:video_clips][:add].partition { |vf| vf[:video_file_id].nil? }
          movie_task.add_video_clip_attachment(ids)
          paths.each do |p|
            share = Share.find(p[:share_id])
            tasks << task = Task::Model::BaseFile::VideoFile::Create.new(share: share, path: p[:path])
            movie_task.add_video_clip_attachment(p, task)
          end
        end
        Array(movie_data[:video_clips][:delete]).each do |vcd|
          movie_task.add_video_clip_deletion(vcd[:video_file_id])
          if vcd[:delete_video_file]
            delete_video_files_tasks << Task::Model::BaseFile::VideoFile::Delete.create(model_id: vcd[:video_file_id])
          end
        end
      end

      if movie_data[:poster_file_path].is_a?(String)
        share = Share.find(movie_data[:poster_file_share_id])
        import_poster_task = Task::Model::BaseFile::ImageFile::Create.new(:share => share, :path => movie_data[:poster_file_path])
        tasks << import_poster_task
        movie_task.depend_on(poster_file_task: import_poster_task)
      end

      tasks << movie_task
      tasks.each { |t| t.should_retrieve = !!movie_data[:update_from_metadata] }
      tasks + delete_video_files_tasks
    end

    def validate_import_order(params)
      movie = params[:movie]
      if movie.nil?
        raise Order::OrderValidationError.new "Movie import order cannot be created without any data!"
      elsif !movie[:id].nil?
        raise Order::OrderValidationError.new "Movie import order cannot have ids of the movies it is going to create beforehand!"
      end
      validate_movie_input(movie)
      if [:languages, :genres, :casts, :video_clips].any? {|k| movie.has_key?([k]) && movie[k].has_key?(:delete) }
        raise Order::OrderValidationError.new "Movie import order cannot have any delete keys!"
      end

    end

    def validate_change_order(params)
      movie = params[:movie]
      if movie.nil?
        raise Order::OrderValidationError.new "Movie change order cannot be created without any data!"
      elsif movie[:movie_id].nil?
        raise Order::OrderValidationError.new "Movie change order cannot change movies without ids!"
      end
      validate_movie_input(movie)
    end

    def validate_movie_input(movie_params)
      shape = {
          id:                     Integer,
          update_from_metadata:   Boolean,
          release_date:           Date,
          title:                  String,
          original_title:         String,
          tagline:                String,
          storyline:              String,
          youtube_trailer_source: String,
          poster_file_id:         Integer,
          poster_url:             String,
          poster_file_path:       String,
          poster_file_share_id:   Integer,
          tmdb_id:                Integer,
          imdb_id:                String,
          metacritic_id:          String,
          rotten_tomatoes_id:     String,
          languages: {
            add: [
              {
                name:               String,
                iso_639_1:          String,
              }
            ],
            delete: [
              {
                name:               String,
                iso_639_1:          String,
              }
            ]

          },
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
          casts: {
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
          },
          video_clips: {
            add: [
              {
                path:                 String,
                id:                   Integer,
                set:                  Integer,
                order:                Integer,
                share_id:             Integer,
                video_file_id:        Integer
              }
            ],
            delete: [
              {
                video_file_id:        Integer,
                delete_video_file:    Boolean
              }
            ]
          }
      }
      movie_params.slice(*shape.keys).has_shape?(shape, { allow_undefined_keys: false, allow_missing_keys: true, allow_nil_values: false, error_on_mismatch: true })
      #|| (raise MovieOrder::ValidationError.new "Invalid movie data #{movie_params.inspect}")

      if movie_params[:video_clips]
        if movie_params[:video_clips][:add]
          movie_params[:video_clips][:add].each do |video_clip|
            (video_clip.has_key?(:video_file_id) || video_clip.has_key?(:path) && video_clip.has_key?(:share_id)) ||
                (raise Order::OrderValidationError.new "Video clips must have a share_id and either a path or a video_file_id #{video_clip.inspect}" )
          end
        end
        if movie_params[:video_clips][:delete]
          movie_params[:video_clips][:delete].all? {|dvc| dvc[:video_file_id].is_a?(Integer) } ||
            (raise Order::OrderValidationError.new "Video clip deletes must have a video_file_id #{movie_params[:video_clips][:delete]}" )
        end
      end
    end
  end
end

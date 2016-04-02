module Playful
  module PathResolver
    class PathResolveError < StandardError; end

    def self.attr_for(obj, attr_name, changes)
      if changes.class == Hash && changes.has_key?(attr_name)
        changes[attr_name]
      else
        obj.send(attr_name)
      end
    end

    def self.default_path_for_file(base_file)
      base_file.class.to_s.gsub('::', '_') + '_' + (base_file.id || 'id').to_s + '.' + base_file.file_type.extension
    end

    def self.sanitize_filename(filename)
      fn = filename.strip
      basename = fn.gsub(/^.*(\\|\/)/, '')
      basename_changed = basename.gsub(/[^0-9A-Za-z .\-]/, '')
      fn[fn.length-basename.length..fn.length] = basename_changed
      fn
    end

    module Audio
      # pattern for a files placement is
      # first letter of artist / artist / album? / disc? / artist - track number - track title . extension

      def self.album_path_for_file(audio_file, changes)
        album = PathResolver::attr_for(audio_file, :album, changes)
        disc_number = PathResolver::attr_for(audio_file, :disc_number, changes)
        disc_total = PathResolver::attr_for(audio_file, :disc_total, changes)

        if album.blank?
          raise PathResolveError.new "Cannot find path for album for file #{audio_file.path} because it doesn't have an album defined"
        end

        path = ::File.join(artist_path_for_file(audio_file, changes), album)
        if !disc_number.nil? && !disc_total.nil? && disc_total > 1
          path = ::File.join(path, disc_number)
        end
        path
      end

      def self.path_for_file(audio_file)
        track = audio_file.reference_track
        file_path = PathResolver::default_path_for_file(audio_file)
        unless track.nil?
          artist = track.release.nil? ? track.artist : track.release.artist
          if artist.blank?
            raise PathResolveError.new 'Cannot resolve path for audio file with no artist specified'
          end
          artist_path = ::File.join(artist[0].upcase, artist)
          track_number_str = track.track_number.blank? ? '' : "#{sprintf('%02d', track.track_number)} - "
          filename_no_ext = "#{artist} - " + track_number_str + "#{track.title}"
          filename = filename_no_ext + '.' + audio_file.file_type.extension
          prefix = artist_path
          unless track.release.nil?
            prefix = ::File.join(prefix, track.release.title)
            if track.release.disc_total > 1 && !track.disc_number.nil?
              prefix = ::File.join(prefix, track.disc_number)
            end
          end
          file_path = ::File.join(prefix, filename)
        end

        abs_path = audio_file.share.fs_path(::File.join(music_base_path, file_path))
        unless track.nil?
          if track.audio_clips.length > 1
            abs_path.gsub!(/(.*)\.([^.]*)$/, "\\1 (#{audio_file.id.to_s}).\\2")
          end
        end
        PathResolver::sanitize_filename(abs_path)
      end

      protected

      def self.music_base_path
        'Music'
      end

      def self.archive_artist(audio_file, changes)
        artist = PathResolver::attr_for(audio_file, :artist, changes)
        album_artist = PathResolver::attr_for(audio_file, :album_artist, changes)

        if artist.blank? && album_artist.blank?
          raise PathResolveError.new "Cannot find path for artist for file #{audio_file.path} because it doesn't have an artist or album artist defined"
        end

        artist || album_artist
      end

      def self.artist_path_for_file(audio_file, changes)
        archive_artist = archive_artist(audio_file, changes)
        artist_first_letter = archive_artist[0].upcase
        ::File.join(artist_first_letter, archive_artist)
      end

    end

    module Image
      def self.path_for_movie_poster(image_file, movie)
        name = movie.title + ' - poster.' + image_file.file_type.extension
        path = image_file.share.fs_path(::File.join(Video.path_for_movie(movie), name))
        result = ::File.exists?(path) ? path.gsub(/(.*)\.([^.]*)$/, "\\1 (#{image_file.id.to_s}).\\2") : path
        PathResolver::sanitize_filename(result)
      end

      def self.path_for_episode_poster(image_file, episode)
        name = episode.name || "Episode #{episode.episode_number}"
        name += ' - poster.' + image_file.file_type.extension
        path = image_file.share.fs_path(::File.join(Video.path_for_season(episode.season), name))
        result = ::File.exists?(path) ? path.gsub(/(.*)\.([^.]*)$/, "\\1 (#{image_file.id.to_s}).\\2") : path
        PathResolver::sanitize_filename(result)
      end

      def self.path_for_season_poster(image_file, season)
        name = 'Season poster.' + image_file.file_type.extension
        path = image_file.share.fs_path(::File.join(Video.path_for_season(season), name))
        result = ::File.exists?(path) ? path.gsub(/(.*)\.([^.]*)$/, "\\1 (#{image_file.id.to_s}).\\2") : path
        PathResolver::sanitize_filename(result)
      end
    end

    module Video
      def self.path_for_movie(movie)
        p = movie.title
        unless movie.release_date.nil?
          p += " [#{movie.release_date.year}]"
        end
        ::File.join(movie_base_path, p)
      end

      def self.path_for_tv_series(tv_series)
        ::File.join(tv_series_base_path, tv_series.name)
      end

      def self.path_for_season(season)
        ::File.join(path_for_tv_series(season.tv_series), "Season #{season.season_number}")
      end

      def self.path_for_file(video_file, opts = {})
        movie = opts[:movie]
        episode = opts[:episode]
        if !movie.nil?
          prefix_path = path_for_movie(movie)
          name = movie.title
          attachable = movie
        elsif !episode.nil?
          prefix_path = path_for_season(episode.season)
          attachable = episode
          name = episode.name || "Episode #{episode.episode_number}"
        else
          raise StandardError.new 'Cannot resolve path for video file, no attachable given'
        end

        my_idx = attachable.video_clips.index(attachable.video_clips.select { |vc| vc.video_file.id == video_file.id }.first)
        total = attachable.video_clips.length
        clip_path = ::File.join(prefix_path, "#{name} - part #{my_idx + 1} of #{total}.#{video_file.file_type.extension}")
        path = video_file.share.fs_path(clip_path)
        result = ::File.exists?(path) ? path.gsub!(/(.*)\.([^.]*)$/, "\\1 (#{video_file.id.to_s}).\\2") : path
        PathResolver::sanitize_filename(result)
      end

      protected

      def self.movie_base_path
        'Movies'
      end

      def self.tv_series_base_path
        'Series'
      end

    end

  end
end

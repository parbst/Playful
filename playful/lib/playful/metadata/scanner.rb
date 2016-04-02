require 'playful/metadata/driver/spotify'
require 'playful/metadata/driver/the_movie_db'

module Playful
  module Metadata

    class Scanner
      def initialize(options = {})
        @audio_drivers = {
            :spotify => Playful::Metadata::Driver::Spotify.new
        }
        @video_drivers = {
            :tmdb => Playful::Metadata::Driver::TheMovieDb.new(options[:tmdb_api_key])
        }
      end

      # {
      #   :text => {
      #     :artist_name => 'artist name',
      #   },
      #   :spotify => {
      #     :artist_id => 'driver specific id'
      #   }
      # }
      def artist_search(artist_desc)
        merge_artist_search_results search(@audio_drivers, :artist_search, :text, :artist_name, artist_desc)
      end

      def artist_lookup(artist_desc)
        l = lookup(@audio_drivers, artist_desc, :artist_id) { |driver, args| driver.artist_lookup args[:artist_id] }
        merge_artist_lookup_results l
      end

      # {
      #   :text => {
      #     :release_name => 'release name'
      #   },
      #   :spotify => {
      #     :release_id => 'driver specific id',
      #     :artist_id => 'driver specific artist id'
      #   }
      # }
      def release_search(release_desc)
        do_text_search = release_desc.has_key?(:text) && release_desc[:text].has_key?(:release_name) &&
            release_desc[:text][:release_name].to_s.strip.length > 0
        results = []
        if do_text_search
          results += @audio_drivers.values.map { |d| d.release_search(release_desc[:text][:release_name]) }.flatten
        end

        # do artist_id search
        possible_keys = release_desc.keys.select { |k|
          @audio_drivers.has_key?(k) && release_desc[k].has_key?(:artist_id) && release_desc[k][:artist_id].to_s.strip.length > 0
        }
        results + possible_keys.map do |key|
          @audio_drivers[key].release_lookup_by_artist(release_desc[key][:artist_id])
        end.flatten
      end

      def release_lookup(release_desc)
        l = lookup(@audio_drivers, release_desc, :release_id) { |driver, args| driver.release_lookup(args[:release_id]) }
        merge_release_lookup_results l
      end

      # {
      #   :text => {
      #     :movie_title => 'title of movie'
      #   },
      #   :tmdb => {
      #     :movie_id  => 'driver specific id',
      #   }
      # }
      def movie_search(movie_desc)
        merge_movie_search_results(search(@video_drivers, :movie_search, :text, :movie_title, movie_desc))
      end

      def movie_lookup(movie_desc)
        l = lookup(@video_drivers, movie_desc, :movie_id) { |driver, args| driver.movie_lookup args[:movie_id] }
        merge_movie_lookup_results l
      end

      # {
      #   :text => {
      #     :tv_series_title => 'title of tv series'
      #   },
      #   :tmdb => {
      #     :tv_series_id  => 'driver specific id',
      #   }
      # }
      def tv_series_search(desc)
        merge_tv_series_search_results search(@video_drivers, :tv_series_search, :text, :tv_series_title, desc)
      end

      def tv_series_lookup(desc)
        l = lookup(@video_drivers, desc, :tv_series_id) { |driver, args| driver.tv_series_lookup(args[:tv_series_id]) }
        merge_tv_series_lookup_results l
      end

      def tv_series_season_lookup(desc)
        l = lookup(@video_drivers, desc, [:tv_series_id, :season_number]) do |driver, args|
          driver.tv_series_season_lookup(args[:tv_series_id], args[:season_number])
        end
        merge_tv_series_season_lookup_results l
      end

      def tv_series_episode_lookup(desc)
        l = lookup(@video_drivers, desc, [:tv_series_id, :season_number, :episode_number]) do |driver, args|
          driver.tv_series_episode_lookup(args[:tv_series_id], args[:season_number], args[:episode_number])
        end
        merge_tv_series_episode_lookup_results l
      end

      private

      def lookup(drivers, args, required_keys = nil)
        possible_keys = args.keys.select { |d|
          drivers.has_key?(d) && Array(required_keys).compact.all? { |rk| args[d].has_key?(rk) && args[d][rk].to_s.strip.length > 0 }
        }
        possible_keys.map do |key|
          yield drivers[key], args[key] if block_given?
        end.compact
      end

      def search(drivers, search_method, prefix_key, name_key, args)
        do_search = args.has_key?(prefix_key) && args[prefix_key].has_key?(name_key) &&
            args[prefix_key][name_key].to_s.strip.length > 0
        if do_search
          drivers.values.map { |d| d.send(search_method, args[prefix_key][name_key]) }
        else
          []
        end
      end

      # only one driver as of yet so this is implemented very simple
      def merge_movie_search_results(results)
        results.flatten
      end

      def merge_movie_lookup_results(results)
        results.flatten
      end

      def merge_release_lookup_results(results)
        results.flatten.first
      end

      def merge_artist_lookup_results(results)
        results.flatten
      end

      def merge_artist_search_results(results)
        results.flatten
      end

      def merge_tv_series_search_results(results)
        results.flatten.first
      end

      def merge_tv_series_lookup_results(results)
        results.flatten.first
      end

      def merge_tv_series_season_lookup_results(results)
        results.flatten.first
      end

      def merge_tv_series_episode_lookup_results(results)
        results.flatten.first
      end
    end
  end
end


module Playful
  module Metadata
    module Driver
      class TheMovieDb
        def initialize(api_key)
          @tmdb = Tmdb::Api.key(api_key)
          @configuration = Tmdb::Configuration.new
        end

        def movie_search(movie_title)
          search = Tmdb::Search.new
          search.resource('movie')

          result = []
          unless movie_title.nil?
            search.query(movie_title)
            sr = search.fetch
            result = map_movie_search_response sr
          end

          result
        end

        def movie_lookup(movie_id)
          m = Tmdb::Movie.detail(movie_id)
          m.title.nil? ? {} : map_movie_lookup_response(m, Tmdb::Movie.casts(movie_id), Tmdb::Movie.trailers(movie_id))
        end

        def tv_series_search(tv_series_name)
          result = []
          unless tv_series_name.nil?
            sr = Tmdb::TV.find(tv_series_name)
            result = map_tv_series_common_response sr
          end
          result
        end

        def tv_series_lookup(tv_series_id)
          tvs = Tmdb::TV.detail(tv_series_id)
          result = tvs.id.nil? ? {} : map_tv_series_lookup_response(tvs, Tmdb::TV.external_ids(tv_series_id), Tmdb::TV.cast(tv_series_id))
          result[:tmdb_id] ||= tv_series_id
          result
        end

        def tv_series_season_lookup(tv_series_id, season_number)
          season = Tmdb::Season.detail(tv_series_id, season_number)
          season.symbolize_keys!
          if season[:id].nil?
            {}
          else
            map_tv_series_season_lookup_response(season,
                                                 Tmdb::Season.external_ids(tv_series_id, season_number),
                                                 Tmdb::Season.cast(tv_series_id, season_number))
          end
        end

        def tv_series_episode_lookup(tv_series_id, season_number, episode_number)
          episode = Tmdb::Episode.detail(tv_series_id, season_number, episode_number)
          episode.symbolize_keys!
          if episode[:id].nil?
            {}
          else
            map_tv_series_episode_lookup_response(episode,
                                                  Tmdb::Episode.external_ids(tv_series_id, season_number, episode_number),
                                                  Tmdb::Episode.cast(tv_series_id, season_number, episode_number))
          end
        end

        private

        def map_movie_lookup_response(movie_object, casts, trailers)
          map_movie_common_response({
              :adult              => movie_object.adult,
              :tmdb_backdrop_path => movie_object.backdrop_path,
              :tmdb_poster_path   => movie_object.poster_path,
              :collection         => movie_object.belongs_to_collection,
              :genres             => movie_object.genres,
              :homepage           => movie_object.homepage,
              :tmdb_id            => movie_object.id,
              :imdb_id            => movie_object.imdb_id,
              :original_title     => movie_object.original_title,
              :storyline          => movie_object.overview,
              :release_date       => movie_object.release_date,
              :languages          => movie_object.spoken_languages,
              :tagline            => movie_object.tagline,
              :title              => movie_object.title,
              :tmdb_popularity    => movie_object.popularity,
              :tmdb_vote_average  => movie_object.vote_average,
              :tmdb_vote_count    => movie_object.vote_count,
          }.tap do |o|
            o[:collection] = o[:collection].symbolize_keys unless o[:collection].nil?
            o[:languages] = o[:languages].map { |sl| sl.symbolize_keys } unless o[:languages].nil?
            unless o[:genres].nil?
              o[:genres] = o[:genres].map do |sl|
                sl.symbolize_keys!
                sl[:tmdb_id] = sl.delete(:id)
                sl
              end
            end
            o[:casts] = map_casts(casts)
            if trailers.has_key?("youtube") && trailers["youtube"].length > 0
              o[:youtube_trailer_source] = trailers["youtube"].first()["source"]
            end
          end)
        end

        def map_movie_search_response(response)
          result = Array(response).map do |r|
            map_movie_common_response({
                :adult              => r["adult"],
                :tmdb_backdrop_path => r["backdrop_path"],
                :tmdb_id            => r["id"],
                :original_title     => r["original_title"],
                :title              => r["title"],
                :release_date       => r["release_date"],
                :tmdb_popularity    => r["popularity"],
                :tmdb_vote_average  => r["vote_average"],
                :tmdb_vote_count    => r["vote_count"],
                :tmdb_poster_path   => r["poster_path"]
            })
          end
          response.is_a?(Array) ? result : result.first
        end

        def map_movie_common_response(o)
          map_posters o
          o[:tmdb] = { :movie_id => o[:tmdb_id] }
          o[:release_date] = Date.parse(o[:release_date]) unless o[:release_date].blank?
          o[:tmdb_update] = DateTime.now
          o
        end

        def map_posters(o)
          base_url = @configuration.base_url
          o[:tmdb_posters] = @configuration.poster_sizes.map { |ps| base_url + ps + o[:tmdb_poster_path] } unless o[:tmdb_poster_path].nil?
          o[:tmdb_backdrops] = @configuration.backdrop_sizes.map { |bs| base_url + bs + o[:tmdb_backdrop_path]  } unless o[:tmdb_backdrop_path].nil?
          o
        end

        def map_casts(casts)
          base_url = @configuration.base_url
          casts ||= []
          casts.map do |a|
            {
              character_name: a["character"],
              actor_name:     a["name"],
              order:          a["order"],
            }.tap do |o|
              o[:character_image_url] = base_url + "w185" + a["profile_path"] unless a["profile_path"].nil?
            end
          end
        end

        def map_tv_series_common_response(response)
          Array(response).map do |r|
            {
              name:               r.name,
              original_name:      r.original_name,
              tmdb_backdrop_path: r.backdrop_path,
              tmdb_poster_path:   r.poster_path,
              tmdb_popularity:    r.popularity,
              tmdb_vote_average:  r.vote_average,
              tmdb_vote_count:    r.vote_count,
              first_air_date:     r.first_air_date,
              tmdb_id:            r.id
            }.tap do |o|
              map_posters o
              o[:description] = r.overview unless r.overview.nil?
              unless response.genres.nil?
                o[:genres] = response.genres.map do |sl|
                  sl.symbolize_keys!
                  sl[:tmdb_id] = sl.delete(:id)
                  sl
                end
              end
              o[:number_of_episodes] = r.number_of_episodes unless r.number_of_episodes.nil?
              o[:number_of_seasons] = r.number_of_seasons unless r.number_of_seasons.nil?
            end
          end
        end

        def map_tv_series_lookup_response(response, external_ids, cast)
          map_tv_series_common_response(response).first.tap do |r|
            [:imdb_id, :freebase_id, :tmdb_id].each do |key|
              r[key] = external_ids[key.to_s]
            end
            r[:casts] = map_casts(cast)
          end
        end

        def map_tv_series_season_lookup_response(response, external_ids, cast)
          {
            description:        response[:overview],
            tmdb_id:            response[:id],
            season_number:      response[:season_number],
            name:               response[:name],
            air_date:           response[:air_date],
            number_of_episodes: response[:episodes].length
          }.tap do |o|
            o[:tmdb_id]     = external_ids['id']
            o[:freebase_id] = external_ids['freebase_id']
            o[:casts]       = map_casts(cast)
            o[:poster_url] = @configuration.base_url + "w185" + response[:poster_path] unless response[:poster_path].nil?
          end
        end

        def map_tv_series_episode_lookup_response(response, external_ids, cast)
          {
            air_date:         response[:air_date],
            episode_number:   response[:episode_number],
            name:             response[:name],
            description:      response[:overview],
            tmdb_id:          response[:id],
            season_number:    response[:season_number],
          }.tap do |o|
            o[:freebase_id] = external_ids['freebase_id']
            o[:imdb_id]     = external_ids['imdb_id']
            o[:casts]       = map_casts(cast)
            o[:poster_url] = @configuration.base_url + "w185" + response[:still_path] unless response[:still_path].nil?
          end
        end
      end
    end
  end
end

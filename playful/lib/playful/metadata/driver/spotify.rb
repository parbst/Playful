require "uri"
require "net/http"
require "json"
require 'playful/metadata'

module Playful
  module Metadata
    module Driver

      class Spotify
        SPOTIFY_BASE_URL    = 'ws.spotify.com'
        SPOTIFY_API_VERSION = 1

        def artist_search(artist_name)
          path = "/search/#{SPOTIFY_API_VERSION}/artist.json?q=#{URI.encode(artist_name)}"
          r = execute_query(path)
          r['artists'].map { |raw| map_artist(raw)}
        end

        def artist_lookup(artist_id)
          path = "/lookup/#{SPOTIFY_API_VERSION}/.json?uri=#{URI.encode(artist_id)}"
          r = execute_query(path)
          map_artist(r['artist'])
        end

        def release_lookup_by_artist(artist_id)
          path = "/lookup/#{SPOTIFY_API_VERSION}/.json?uri=#{URI.encode(artist_id)}&extras=albumdetail"
          r = execute_query(path)
          r['artist']['albums'].map { |raw| map_album(raw['album'])}
        end

        def release_search(release_name)
          path = "/search/#{SPOTIFY_API_VERSION}/album.json?q=#{URI.encode(release_name)}"
          r = execute_query(path)
          r['albums'].map { |raw| map_album(raw)}
        end

        def release_lookup(release_id)
          path = "/lookup/#{SPOTIFY_API_VERSION}/.json?uri=#{URI.encode(release_id)}&extras=trackdetail"
          r = execute_query(path)
          map_album(r['album'], r['info'])
        end

        private

        def execute_query(path)
          http = Net::HTTP.new(SPOTIFY_BASE_URL)
          puts "spotify execute query\n#{path}\n#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
          r = http.get(path)
          unless r.is_a?(Net::HTTPSuccess)
            raise MetadataError.new "Failed to execute query #{path}, error #{r.code_type.to_s}: #{r.body}"
          end
          JSON.parse(r.body)
        end

        def map_artist(raw)
          {
            :identifier => {
              :spotify => {
                :artist_id => raw['href']
              },
            },
            :artist_name       => raw['name'].strip
          }.tap { |o|
            o[:popularity] = raw['popularity'] if raw.has_key?('popularity')
          }
        end

        def map_album(raw_album, raw_info = {})
          {
            :identifier => {
              :spotify => {
                :release_id   => raw_album['href']
              }
            },
            :release_name       => raw_album['name'].strip,
          }.tap do |o|
            o[:popularity] = raw_album['popularity'] if raw_album.has_key?('popularity')
            if raw_album.has_key?('tracks')
              o[:tracks] = raw_album['tracks'].map { |t| map_track(t) }
              o[:artists] = o[:tracks].map { |t| t[:artists] }.flatten.uniq
            end
            o[:release_date] = raw_album['released'] if raw_album.has_key?('released')
            if raw_album.has_key?('info') && raw_album['info'].has_key?('type')
              o[:identifier][:spotify][:album_type] = raw_album['info']['type']
            end
            if raw_album.has_key?('artist-id')
              o[:identifier][:spotify][:artist_id] = raw_album['artist-id']
            end
            o[:release_type] = raw_info['type'] if raw_info.is_a?(Hash) && raw_info.has_key?('type')
          end
        end

        def map_track(raw)
          {
            :identifier => {
              :spotify => {
                :track_id => raw['href'],
              }
            },
            :disc_number      => raw['disc-number'].to_i,
            :duration         => raw['length'],
            :title            => raw['name'].strip,
            :track_number     => raw['track-number'].to_i
          }.tap do |o|
            o[:popularity] = raw['popularity'] if raw.has_key?('popularity')
            o[:artists] = raw['artists'].map { |a| map_artist(a) } if raw.has_key?('artists')
          end
        end
      end

    end
  end
end

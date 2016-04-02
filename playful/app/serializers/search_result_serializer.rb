class SearchResultSerializer < ActiveModel::Serializer
  attributes :current_page, :per_page, :total_count, :results,
             :movies, :tracks, :tv_series, :seasons, :episodes, :releases#, :languages, :genres

  def movies
    object.movies.map { |movie| MovieSerializer.new(movie, root: false) }
  end

  def tracks
    object.tracks.map { |track| TrackSerializer.new(track, root: false) }
  end

  def tv_series
    object.tv_series.map { |tv_series| TvSeriesSerializer.new(tv_series, root: false) }
  end

  def seasons
    object.seasons.map { |season| SeasonSerializer.new(season, root: false) }
  end

  def episodes
    object.episodes.map { |episode| EpisodeSerializer.new(episode, root: false) }
  end

  def releases
    object.releases.map { |release| ReleaseSerializer.new(release, root: false) }
  end

  def languages
    all_languages = object.movies.map {|m| m.languages }.flatten
    all_languages.uniq {|l| l.id }.map {|l| LanguageSerializer.new(l, root: false) }
  end

  def results
    object.all_results.map {|r| { type: r.class.to_s.camelcase(:lower), id: r.id } }
  end

end

#class UsersSerializer < ActiveModel::Serializer
#  attributes :total, :page, :per_page, :first_page?, :last_page?, :users
#  attribute :length, key: :returned_count
#
#  def users
#    object.results.map {|u| UserSerializer.new(u)}
#  end
#end

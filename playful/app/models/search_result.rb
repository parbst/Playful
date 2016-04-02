# http://rahil.ca/blog/how-to-set-up-a-rails-search-api-with-json-and-sunspot-solr/#searchable
class SearchResult
  include ActiveModel::SerializerSupport

  def initialize(sunspot_search_result)
    @search_result = sunspot_search_result
  end

  def all_results
    @results ||= @search_result.results
  end

  def current_page
    @search_result.results.current_page
  end

  def per_page
    @search_result.results.per_page
  end

  def total_count
    @search_result.results.total_count
  end

  def hits
    @search_result.hits
  end

  def movies
    all_results.select { |r| r.is_a?(Movie) }
  end

  def tracks
    all_results.select { |r| r.is_a?(Track) }
  end

  def tv_series
    all_results.select { |r| r.is_a?(TvSeries) }
  end

  def seasons
    all_results.select { |r| r.is_a?(Season) }
  end

  def episodes
    all_results.select { |r| r.is_a?(Episode) }
  end

  def releases
    all_results.select { |r| r.is_a?(Release) }
  end

end

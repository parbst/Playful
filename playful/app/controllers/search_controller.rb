class SearchController < ApplicationController
  respond_to :json, :xml

  def search
    respond_to do |format|
      format.json { render json: do_search_from_spec(params) }
    end
  end

  private

  def do_search_from_spec(params)
    params_shape = {
      text:             String, # free text search
      types:            [String], # list of search results to find:  movie, tv_series, episode, season, release, track
      with_facets:      Boolean,
      page:             Integer,
      per_page:         Integer,
      facets: {
        movie: {
          genres:       String,
          languages:    String,
          casts:        [String]
        },
        tv_series: {
          genres:       String,
          languages:    String,
          casts:        [String]
        },
        track: {
          title:        String,
          artist:       String,
          year:         String,
          disc_number:  String,
          release_id:   Integer
        },
        release: {
          name:         String,
          artist:       String,
          year:         String,
          genre:        String,
        },
        season: {
          tv_series_id: Integer,
        },
        episode: {
          tv_series_id: Integer,
        }
      }
    }

    shape_opts = { allow_undefined_keys: false, allow_missing_keys: true, allow_nil_values: true, error_on_mismatch: true }
    unless params.has_shape?(params_shape, shape_opts)
      raise "Malformed params. They should look like #{params_shape.inspect}"
    end

    search_for_classes = [Movie, TvSeries, Episode, Season, Release, Track]
    unless params[:types].nil?
      search_for_classes.select! {|c| params[:types].include?(c.to_s.underscore) }
    end

#    s = Sunspot.search BaseFile, BaseFile::AudioFile do |query|
#      query.keywords 'primus'
#      query.with(:track_number).greater_than 10
#      query.with(:byte_size).greater_than 1324
#    end
    search = Sunspot.search search_for_classes do |query|
      query.keywords params[:text]

      unless !params[:with_facets] || params[:facets].nil?
        with_values = {}
        params[:facets].keys.select {|k| params[:types].include?(k) }.each do |type_key|
          params[:facets][type_key].keys.each do |facet_key|
            with_values[facet_key] = params[:facets][type_key] if with_values[facet_key].nil?
          end
        end
        with_values.each do |key, value|
          query.with(key, value)
        end
      end

      query.paginate :page => params[:page] || 1, :per_page => params[:per_page] ||50

      if !params[:with_facets].nil? && params[:with_facets]
        params_shape[:facets].keys.map { |k| params_shape[:facets][k].keys }.flatten.uniq.each do |facet|
          query.facet facet
        end
      end
    end

    SearchResult.new(search)
  end

end


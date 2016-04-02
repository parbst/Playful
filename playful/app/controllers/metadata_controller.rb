class MetadataController < ApplicationController
  respond_to :json, :xml

  before_filter :sanatize_input

  def initialize
    super
    @scanner = Playful::Factory.metadata_scanner
  end

  def artist
    result = @scanner.artist_lookup(@input) + @scanner.artist_search(@input)
    respond_to do |format|
      format.json { render :json  => result }
      format.xml  { render :xml   => result }
    end
  end

  def release
    result = @scanner.release_search(@input)
    lookup = @scanner.release_lookup(@input)
    result.unshift(lookup) unless lookup.nil?
    respond_to do |format|
      format.json { render :json  => result }
      format.xml  { render :xml   => result }
    end
  end

  def movie
    result = @scanner.movie_lookup(@input)
    unless result.length > 0
      result = @scanner.movie_search(@input)
    end
    respond_to do |format|
      format.json { render :json  => result }
      format.xml  { render :xml   => result }
    end
  end

  protected

  def default_serializer_options
    { root: false }
  end

  def sanatize_input
    @input = {}
    params.keys.select { |k| params[k].is_a?(Hash) }.each do |k|
      @input[k] = params[k]
    end
    @input = @input.recursive_symbolize_keys
  end
end

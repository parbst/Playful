class Cast < ActiveRecord::Base
  belongs_to :movie
  belongs_to :tv_series
  belongs_to :season
  belongs_to :episode
  belongs_to :actor
  belongs_to :character_image, foreign_key: 'image_file_id', class_name: 'BaseFile::ImageFile'

  validate :only_one_reference

  protected

  def only_one_reference
    unless movie.nil? && tv_series.nil? && episode.nil? && season.nil? ||
           movie.nil? ^ tv_series.nil? ^ episode.nil? ^ season.nil?
      errors.add :reference, 'a cast must belong to one and only one piece'
    end
  end

  def self.ensure(params)
    if params[:actor].is_a?(Actor)
      params[params[:model].class.to_s.underscore.to_sym] ||= params[:model]

      model = nil
      if params[:movie].is_a?(Movie) && !params[:movie].new_record?
        model = Cast.where(movie_id: params[:movie].id, actor_id: params[:actor].id).first
      elsif params[:tv_series].is_a?(TvSeries) && !params[:tv_series].new_record?
        model = Cast.where(tv_series_id: params[:tv_series].id, actor_id: params[:actor].id).first
      elsif params[:episode].is_a?(Episode) && !params[:episode].new_record?
        model = Cast.where(episode_id: params[:episode].id, actor_id: params[:actor].id).first
      elsif params[:season].is_a?(Season) && !params[:season].new_record?
        model = Cast.where(season_id: params[:season].id, actor_id: params[:actor].id).first
      end

      if model.nil?
        model = Cast.new(movie: params[:movie],
                         actor: params[:actor],
                         episode: params[:episode],
                         season: params[:season],
                         tv_series: params[:tv_series],
                         order: params[:order],
                         character_image: params[:character_image],
                         character_image_url: params[:character_image_url],
                         character_name: params[:character_name])
      end

      model
    end
  end

end

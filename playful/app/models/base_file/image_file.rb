class BaseFile::ImageFile < BaseFile # ActiveRecord::Base
#  inherits_from :base_file      # for the class-table-inheritance plugin
#  include BaseFile::Inherits

  has_many :episodes, foreign_key: 'poster_file_id', inverse_of: :poster_file
  has_many :collections, foreign_key: 'poster_file_id', inverse_of: :poster_file
  has_many :movies, foreign_key: 'poster_file_id', inverse_of: :poster_file
  has_many :album_back_covers, foreign_key: 'back_cover_id', inverse_of: :back_cover
  has_many :album_front_covers, foreign_key: 'front_cover_id', inverse_of: :front_cover

  validates_numericality_of :height, :width, :only_integer => true, :greater_than_or_equal_to => 0

  def update_from_scan(scan)
    super(scan)
    if scan.has_key?(:ffmpeg) && scan[:ffmpeg].has_key?(:video)
      self.height = scan[:ffmpeg][:video][:height]
      self.width = scan[:ffmpeg][:video][:width]
    end
    if scan.has_key?(:file)
      self.comment = scan[:file][:comment]
    end
  end

  def resolved_path
    if episodes.any?
      ::Playful::PathResolver::Image.path_for_episode_poster(self, episodes.first)
    elsif collections.any? && collections.first.is_a?(Season)
      ::Playful::PathResolver::Image.path_for_season_poster(self, collections.first)
    elsif movies.any?
      ::Playful::PathResolver::Image.path_for_movie_poster(self, movies.first)
    else
      super()
    end
  end

end

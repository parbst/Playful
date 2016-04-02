class VideoClip < Clip
  belongs_to :video_file, :class_name => "BaseFile::VideoFile", :foreign_key => 'base_file_id'

  validates :video_file, :presence => true
  validate :video_has_correct_class
  validate :correct_reference

  def self.ensure(params)
    if params[:video_file].is_a?(BaseFile::VideoFile)

      if params[:model].is_a?(Movie)
        params[:movie] ||= params[:model]
      elsif params[:model].is_a?(Episode)
        params[:episode] ||= params[:model]
      end

      model = nil
      if params[:movie].is_a?(Movie)
        model = VideoClip.where(movie_id: params[:movie].id, base_file_id: params[:video_file].id).first
      elsif params[:episode].is_a?(Episode)
        model = VideoClip.where(collection_item_id: params[:episode].id, base_file_id: params[:video_file].id).first
      end

      if model.nil?
        model = VideoClip.new(:name             => params[:name],
                              :order            => params[:order],
                              :set              => params[:set],
                              :movie            => params[:movie],
                              :video_file       => params[:video_file],
                              :collection_item  => params[:episode])
      end

      model
    end
  end

  def self.valid_creation_data?(params)
    params.has_shape?({
      set:              Integer,
      order:            Integer,
      video_file_id:    Integer
    }, { allow_undefined_keys: true, allow_missing_keys: true })
  end

  protected

  def video_has_correct_class
    errors.add('video_file', "Incorrect file type") unless video_file.nil? || video_file.is_a?(BaseFile::VideoFile)
  end

  def correct_reference
    if movie.nil? && collection_item.nil?
      errors.add :no_reference, "A video clip must belong to either a movie or a collection item"
    end
  end

end

class AudioClip < Clip
  belongs_to :audio_file, :class_name => "BaseFile::AudioFile", :foreign_key => 'base_file_id'

  validates :audio_file, :collection_item, :presence => true
  validate :audio_has_correct_class
  validate :only_one_primary_track

  alias_attribute :track, :collection_item

  def self.ensure(params)
    if params[:audio_file].is_a?(BaseFile::AudioFile)

      if params[:model].is_a?(Track)
        params[:track] ||= params[:model]
      end

      model = nil
      if params[:track].is_a?(Track)
        model = AudioClip.where(base_file_id: params[:audio_file].id, collection_item_id: params[:track].id).first
      end

      if model.nil?
        model = AudioClip.new(:name             => params[:name],
                              :order            => params[:order],
                              :set              => params[:set],
                              :audio_file       => params[:audio_file],
                              :collection_item  => params[:track])
      end

      model
    end
  end

  protected

  def only_one_primary_track
    other_primary_clips = AudioClip.where(base_file_id: self.base_file_id, primary_track: true).select {|ac| ac.id != self.id }.length > 0
    if other_primary_clips && self.primary_track
      errors.add('primary_track', 'An audio file may only have one primary track')
    end
  end

  def audio_has_correct_class
    errors.add('audio_file', "Incorrect file type") unless audio_file.nil? || audio_file.is_a?(BaseFile::AudioFile)
  end

end

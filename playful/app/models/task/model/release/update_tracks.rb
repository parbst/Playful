class Task::Model::Release::UpdateTracks < Task::Model::Release

  TYPE = 'releaseUpdateTracksTask'
  def execute
    @model = model
    if @model
      retrieve
      @model.save!
      @model.tracks.select(&:changed?).each do |t|
        t.save!
        t.resolve_clips!
      end
    end
  end

end
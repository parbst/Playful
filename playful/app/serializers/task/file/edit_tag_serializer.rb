class Task::File::EditTagSerializer < Task::FileSerializer
  attributes :path, :old_tags, :new_tags, :cover_art_front
  has_one :base_file, embed: :ids

  def cover_art_front
    it = object.dependee_by_name(:cover_art_front)
    { type: it.task_type, id: it.id } unless it.nil?
  end
end

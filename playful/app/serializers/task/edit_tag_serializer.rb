class Task::EditTagSerializer < TaskSerializer
  attributes :path, :old_tags, :new_tags
  has_one :base_file, embed: :ids
end

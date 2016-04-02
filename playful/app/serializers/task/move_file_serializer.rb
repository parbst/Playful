class Task::MoveFileSerializer < TaskSerializer
  attributes :from_path, :to_path, :create_missing_dirs, :overwrite_existing
  has_one :base_file, embed: :ids
end

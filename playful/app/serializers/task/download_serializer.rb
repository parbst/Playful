class Task::DownloadSerializer < TaskSerializer
  attributes :to_path, :url
  has_one :task_move_file, embed: :ids
end

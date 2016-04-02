class Task::File::DownloadSerializer < Task::FileSerializer
  attributes :to_path, :url
end

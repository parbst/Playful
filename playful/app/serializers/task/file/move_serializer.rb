class Task::File::MoveSerializer < Task::FileSerializer
  attributes :from_path, :to_path, :create_missing_dirs, :overwrite_existing, :input_task
  has_one :base_file, embed: :ids

  def input_task
    it = object.dependee_by_name(:input_task)
    { type: it.task_type, id: it.id } unless it.nil?
  end
end

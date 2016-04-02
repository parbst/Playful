class Task::File < Task
  def input_file_path
    base_file_id.nil? ? path : base_file.path
  end

  def output_file_path
    input_file_path
  end
end

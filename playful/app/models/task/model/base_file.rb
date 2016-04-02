class Task::Model::BaseFile < Task::Model

  belongs_to :base_file
  belongs_to :share

  validates :share_id, :presence => true
  validate :file_exists

  def input_file_path
    input_task = dependee_by_name(:input_task)
    if input_task.nil?
      path
    else
      input_task.output_file_path
    end
  end

  def file_exists
    if (pending? || running?) && dependee_by_name(:input_task).nil? && !::File.file?(path || '')
      errors.add('path', "No dependency move task specified or no such file '#{path}'")
    end
  end

  def retrieve
    @model.scan_and_update
  end

  def update_fields(dummy)
    @model.share = share
  end

  def ensure_defaults
    super()
    self.should_retrieve = true
  end

  protected

  def setup
    super()
    @valid_task_dependees[:input_task] = Task::File
  end

end

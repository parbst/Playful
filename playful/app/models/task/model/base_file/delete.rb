class Task::Model::BaseFile::Delete < Task::Model::Delete

  def execute
    path = model.path
    super # deletes the model
    File.unlink path if File.exists?(path)
  end

  def setup
    super
    @valid_task_dependees[:input_task] = Task::Model::BaseFile
  end

  protected

  def model_must_exist
    unless completed? || failed?
      if model.nil?
        raise "Cannot have an uncompleted delete model task without existing model!"
      end
      unless model.is_a?(::BaseFile)
        raise "The model to be delete must be a base file model. Is was a #{model.class.to_s}!"
      end
    end
  end
end

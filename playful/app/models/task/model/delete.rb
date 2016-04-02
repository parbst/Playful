class Task::Model::Delete < Task::Model

  validate :model_must_exist

  def execute
    @model = model
    if @model
      @model.destroy
    end
  end

  def setup
    super
    @valid_task_dependees[:input_task] ||= Task::Model
  end

  def model(m_id = model_id, m_type = model_type)
    result = super
    if result.nil?
      input_task = dependee_by_name(:input_task)
      result = input_task.model if input_task
    end
    result
  end

  def self.create_from_params(params)
    raise "here!"
    t = Task::Model::Delete.new
    m = t.model(params[:model_id], params[:model_type])
    t.embrace(m)
    t
  end

  protected

  def model_must_exist
    unless completed? || failed?
      if model.nil?
        raise "Cannot have an uncompleted delete model task without existing model!"
      end
    end
  end
end

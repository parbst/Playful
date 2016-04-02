class Task::Model < Task

  store :model_store, accessors: [:nil_valued_fields]

  def after_initialize
    @model = nil
    self.nil_valued_fields ||= []
  end

  def embrace(m = @model)
    self.model_type = m.class.to_s
    self.model_id = m.id
  end

  def model_default(m_id = model_id, m_type = model_type)
    m_type.constantize.find(m_id)
  end

  def model?
    begin
      !!model
    rescue NoMethodError
      false
    end
  end

  def model(m_id = model_id, m_type = model_type)
    model_default(m_id, m_type)
  end

  def model_or_alt_id(alt_id = nil, model_type = nil)
    result = self.model_id.nil? ? nil : model_default

    if !result && !alt_id.nil? && !send(alt_id).nil? && !model_type.nil?
      result = model_default(send(alt_id), model_type)
    end

    result
  end

  def model_alt_id_or_input_task(task_name = :input_task, alt_id = nil, model_type = nil)
    result = model_or_alt_id(alt_id, model_type)

    unless result
      task = dependee_by_name(task_name)
      if  task
        result = task.model
      end
    end

    result
  end

#  def self.model_fields
#    raise 'Task::Model No model_fields for non specific task model class'
#  end

  def self.create_from_params(params)
    model_task = self.new
    model_task.update_attributes_from_params(params)
    model_task.nil_valued_fields = (self.model_fields & params.keys).select {|f| params[f].nil? }
    model_task.should_retrieve = !!params[:update_from_metadata]
    model_task
  end

  def update_attributes_from_params(params)
    self.attributes = Hash[self.class.model_fields.map {|f| [f, params[f]]}]
  end

  def relative_model_class
    self.class.to_s.gsub(/^#{Task::Model.to_s}::/, '').gsub(/::[^:]*$/, '').constantize
  end

  def update_model_fields(field_names, overwrite_with_nil = false)
    a = {}
    field_names.each do |f|
      cur_val = @model.send(f)
      new_val = self.send(f)
      a[f] = new_val if cur_val.nil? || new_val != cur_val && (!new_val.nil? || (overwrite_with_nil && nil_valued_fields.include?(f)))
    end
    @model.attributes = a
  end

  def add_update_and_save
    add_model
    update_model
    save_model
  end

  def retrieve; end

  def update_fields(overwrite = false, fields = self.class.model_fields)
    update_model_fields(fields, overwrite)
  end

  protected

  def add_model
    @model ||= relative_model_class.new
  end

  def update_model(overwrite = false)
    update_model_fields(@model.class.searchable_ids.keys) if @model.class.respond_to?(:searchable_ids)
    retrieve if self.should_retrieve
    update_fields(overwrite)
  end

  def save_model
    @model.save!
    embrace
  end
end

class Task::ModelSerializer < TaskSerializer
  attributes :models

  def attributes
    data = super
    if object.class.respond_to?(:model_fields)
      object.class.model_fields.each do |f|
        data[f] = object.send(f)
      end
    end
    if object.valid_task_dependees.has_key?(:input_task)
      it = object.dependee_by_name(:input_task)
      data[:input_task] = { type: it.task_type, id: it.id } unless it.nil?
    end

    data
  end

  def models
    [].tap do |a|
      if object.model?
        model = object.model
        a << { id: model.id, type: model.respond_to?(:model_type) ? model.model_type : model.class.to_s }
      end
    end
  end

end

require 'active_support/concern'

module PosterAttachableTask
  extend ActiveSupport::Concern

  included do
    validate :only_one
  end

  # opts means like { field_on_model => name_of_input_task }
  def attach_poster_file(opts = { poster_file: :poster_file_task })
    args = {}
    opts.each do |model_field, input_task_name|
      image_task = dependee_by_name(input_task_name)
      if image_task
        args[model_field] = image_task.model
      end
    end
    @model.attributes = args
    @model.save!
    opts.keys.map { |k| @model.public_send(k) }.compact.each(&:resolve_path!)

    opts.keys.each do |model_field|
      model_id_field = (model_field.to_s + '_id').to_sym
      @model[model_id_field] = self[model_id_field] unless self[model_id_field].nil?
    end
    @model.save! if @model.changed? || @model.new_record?
  end

  def only_one
    if @valid_task_dependees.keys.include?(:poster_file_task) && dependee_by_name(:poster_file_task) && self.poster_file_id
      errors.add(:poster_file, 'Poster file update or creation cannot happen with both id and imported file')
    end
  end
end

class TaskSerializer < ActiveModel::Serializer
  attributes :id, :status, :message, :backtrace, :sequence, :type, :created_at, :updated_at,
             :overwrite_model_values, :order_id#, :base_file_id,
#  has_one :order #, embed: :ids

  def type
    object.task_type
  end
end

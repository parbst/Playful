class OrderSerializer < ActiveModel::Serializer
#  self.root = false
  attributes :id, :type, :status, :message, :backtrace, :sequence, :created_at, :updated_at, :parent_order_id, :tasks
  has_many :sub_orders, embed: :ids, include: false
#  has_many :tasks#, embed: :ids, embed_in_root: true, polymorphic: true
# for some reason has_one ain't working with the parent order so it's added manually as parent_order_id
#  has_one :parent_order, embed: :ids

  # trick the serializer into side loading the tasks
#  has_many :tasks_side_loaded, embed_in_root: true, root: :tasks#, embed: :ids
#  def tasks_side_loaded
#    object.tasks.map { |task| TaskSerializer.new(task).as_json['task'] }
#  end

  def tasks
    object.tasks.map do |t|
      {
          # according to ember data docs, the keys were supposed to be task and taskType but apparently that was changed
          id: t.id,
          type: t.task_type
      }
    end
  end

  def type
    object.order_type
  end
end

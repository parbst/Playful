require 'order/file'
require 'task/file'

class Order::File::EditTag < Order::File
  TYPE = "edit_tags"
  def setup
    @valid_task_types = [Task::File::EditTag::TYPE]
  end
end

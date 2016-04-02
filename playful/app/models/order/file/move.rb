require_dependency 'task/file/move'
require 'order/file'

class Order::File::Move < Order::File
  TYPE = "move_files"
  def setup
    @valid_task_types = [Task::File::Move::TYPE]
  end
end

require 'order/file'
require 'task/file/download'

class Order::File::Download < Order::File
  TYPE = "download"
  def setup
    @valid_task_types = [Task::File::Download::TYPE]
  end
end

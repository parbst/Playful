require_dependency 'order/file'
require_dependency 'order/import'
require_dependency 'order/file/download'

class Order::Import::Movie < Order::Import
  include MovieOrder

  TYPE = 'import_movie'

  def setup
    super()
    @valid_task_types = [Task::Model::BaseFile::VideoFile::Create::TYPE,
                         Task::Model::Movie::Create::TYPE,
                         Task::Model::BaseFile::ImageFile::Create::TYPE]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    validate_import_order(params)
    import_order = Order::Import::Movie.new(tasks: create_movie_tasks(params[:movie]))
    import_order.save!
    import_order
  end

end

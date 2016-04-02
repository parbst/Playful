class Order::Change::Movie < Order::Change
  include MovieOrder

  TYPE = 'change_movie'

  def setup
    super()
    @valid_task_types = [Task::Model::BaseFile::VideoFile::Create::TYPE,
                         Task::Model::Movie::Change::TYPE,
                         Task::Model::BaseFile::ImageFile::Create::TYPE,
                         Task::Model::BaseFile::VideoFile::Delete::TYPE]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    validate_change_order(params)
    import_order = Order::Change::Movie.new(tasks: create_movie_tasks(params[:movie]))
    import_order.save!
    import_order
  end
end
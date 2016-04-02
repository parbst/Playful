require_dependency 'order/file'
require_dependency 'order/file/move'
require_dependency 'order/import'
require_dependency 'order/file/download'
require 'playful/path_resolver'

class Order::Change::TvSeries < Order::Change
  include TvSeriesOrder
  TYPE = 'change_tv_series'

  def setup
    super()
    @valid_task_types = [
        Task::Model::BaseFile::VideoFile::Create::TYPE,
        Task::Model::BaseFile::ImageFile::Create::TYPE,
        Task::Model::TvSeries::Change::TYPE,
        Task::Model::Season::Create::TYPE,
        Task::Model::Season::Change::TYPE,
        Task::Model::Episode::Create::TYPE,
        Task::Model::Episode::Change::TYPE,
        Task::Model::Season::Delete::TYPE,
        Task::Model::Episode::Delete::TYPE,
        Task::Model::BaseFile::VideoFile::Delete::TYPE,
        Task::Model::TvSeries::ResolveEpisodeClips::TYPE
    ]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    validate_change_input(params)
    change_order = Order::Change::TvSeries.new
    change_order.tasks = create_tasks(params, Task::Model::TvSeries::Change)
    change_order.save!
    change_order.reload
  end

end
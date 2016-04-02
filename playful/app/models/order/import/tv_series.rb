require_dependency 'app/models/task/model/tv_series/resolve_episode_clips'
require_dependency 'app/models/task/model/tv_series/create'
require_dependency 'app/models/task/model/base_file/video_file/create'
require_dependency 'app/models/task/model/base_file/audio_file/create'
require_dependency 'app/models/task/model/season/create'
require_dependency 'app/models/task/model/episode/create'

class Order::Import::TvSeries < Order::Import
  include TvSeriesOrder
  TYPE = 'import_tv_series'

  def setup
    super()
    @valid_task_types = [
        ::Task::Model::BaseFile::VideoFile::Create::TYPE,
        ::Task::Model::BaseFile::ImageFile::Create::TYPE,
        ::Task::Model::TvSeries::Create::TYPE,
        ::Task::Model::Season::Create::TYPE,
        ::Task::Model::Episode::Create::TYPE,
        ::Task::Model::TvSeries::ResolveEpisodeClips::TYPE
    ]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    validate_import_input(params)
    import_order = Order::Import::TvSeries.new
    import_order.tasks = create_tasks(params)
    import_order.save!
    import_order.reload
  end

end
require 'playful/file/scanner'
require 'playful/path_resolver'
require_dependency 'app/models/order/file/download'

class Order::Import::Audio < Order::Import
  include ::AudioOrder

  TYPE = 'import_audio'

  def setup
    super()
    @valid_task_types = [Task::Model::BaseFile::AudioFile::Create::TYPE,
                         Task::Model::BaseFile::ImageFile::Create::TYPE,
                         Task::Model::Release::Create::TYPE,
                         Task::Model::Track::Create::TYPE,
                         Task::Model::Release::Change::TYPE,
                         Task::Model::Track::Change::TYPE,
                         Task::Model::Track::TagAndResolve::TYPE,
                         Task::Model::Release::UpdateTracks::TYPE]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    import_order = Order::Import::Audio.new(tasks: create_import_from_params(params))
    import_order.save!
    import_order.reload
  end

end

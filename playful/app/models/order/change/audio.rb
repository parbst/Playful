class Order::Change::Audio < Order::Change
  include ::AudioOrder

  TYPE = 'change_audio'

  def setup
    super()
    @valid_task_types = [Task::Model::Release::Change::TYPE,
                         Task::Model::Track::Change::TYPE,
                         Task::Model::Track::TagAndResolve::TYPE,
                         Task::Model::Release::UpdateTracks::TYPE,
                         Task::Model::Track::Delete::TYPE,
                         Task::Model::Release::Delete::TYPE,
                         Task::Model::BaseFile::AudioFile::Delete::TYPE]
    @valid_sub_order_types = [::Order::File::Download::TYPE]
  end

  def self.create_from_params(params)
    change_order = Order::Change::Audio.new(tasks: create_change_from_params(params))
    change_order.save!
    change_order.reload
  end

end
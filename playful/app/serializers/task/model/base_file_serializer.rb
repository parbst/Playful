class Task::Model::BaseFileSerializer < Task::ModelSerializer
  attributes :from_path, :share_id

  def from_path
    share = Share.get_from_abs_path(object.path)
    share.nil? ? object.path : share.to_share_rel_path(object.path)
  end

end

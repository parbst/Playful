require_dependency 'task/model/release'

class Task::Model::Release::Create < Task::Model::Release

  TYPE = 'releaseImportTask'
  def execute
    @model = ::Release.new
    add_update_and_save
    super()
  end

end

class Task::Model::Track::Create < Task::Model::Track

  TYPE = 'trackImportTask'
  def execute
    add_update_and_save
    super()
  end

end
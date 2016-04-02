require 'active_support/concern'

module BaseFileCreateTask
  extend ActiveSupport::Concern

  included do
    validate :import_file_is_not_managed
  end

  def execute
    add_update_and_save
  end

  def ensure_defaults
    super
    self.overwrite_model_values = false
  end

  def import_file_is_not_managed
    unless BaseFile.find_by_path(path).nil? || completed?
      errors.add(:path, "File #{path} to be imported is already under management!")
    end
  end

  protected

  def save_model
    super
    @model.resolve_path!
  end
end
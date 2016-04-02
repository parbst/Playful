require 'fileutils'
require_dependency 'task/file'

class Task::File::Move < Task::File

  belongs_to :base_file

  validates :to_path, :presence => true
  validate :ensure_file_source

  TYPE = 'moveFileTask'

  def execute
    if !overwrite_existing? && ::File.exists?(to_path)
      raise TaskError.new "Move file task not configured for overwriting and file #{to_path} already exists"
    end

    dirname = ::File.dirname(to_path)
    if !::File.directory?(dirname) && create_missing_dirs?
      FileUtils.mkpath dirname
    end

#    FileUtils.mv(from, to_path)
    FileUtils.cp(input_file_path, to_path)

    unless base_file_id.nil?
      self.from_path = base_file.path
      base_file.path = to_path
      base_file.save!
    end
  end

  def input_file_path
    input_task = dependee_by_name :input_task
    if !base_file.nil?
      base_file.path
    elsif !from_path.nil?
      from_path
    elsif !input_task.nil?
      input_task.output_file_path
    end
  end

  def output_file_path
    to_path
  end

  protected

  def setup
    super()
    @valid_task_dependees[:input_task] = Task::File
  end

  private

  def ensure_file_source
    file_must_exist = !(base_file.nil? && from_path.nil?)
    file_path = input_file_path
    input_task = dependee_by_name(:input_task)

    if file_path.nil? && input_task.nil?
      [:base_file_id, :from_path, :dependee_tasks].each { |attr|
        errors.add(attr, "No file source specified '#{attr.to_s}'")
      }
    elsif file_must_exist && !::File.file?(file_path)
      [:base_file_id, :from_path].each { |attr| errors.add(attr, "No such file '#{attr.to_s}'")}
    end

    unless !base_file.nil? ^ !from_path.nil? ^ !input_task.nil?
      [:base_file_id, :from_path, :dependee_tasks].each { |attr|
        errors.add(attr, "Ambiguous source specified, either base_file, from_path or dependee task should be assigned")
      }
    end
  end
end

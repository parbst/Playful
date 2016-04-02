require 'playful/file/driver/tag_driver'

class Task::File::EditTag < Task::File
  belongs_to :base_file
  store :new_tags
  store :old_tags

  validates_presence_of :new_tags
  validates :base_file, :presence => true, :if => 'path.nil?'
  validates :path, :presence => true, :if => 'base_file_id.nil?'
  validate :valid_tag_names
  validate :same_tags
  validate :can_scan

  TYPE = 'editTagFileTask'

  def execute
    check_old_tags
    tag_driver = Playful::File::Driver::TagDriver.new
    front_cover_input_task = dependee_by_name(:cover_art_front)
    args = new_tags.clone
    unless front_cover_input_task.nil?
      args[:cover_art] ||= {}
      args[:cover_art][:front] = front_cover_input_task.output_file_path
    end
    tag_driver.write_tags(input_file_path, args)
  end

  protected

  def setup
    super()
    @valid_task_dependees[:cover_art_front] = Task::File
  end

  private

  def check_old_tags
    tag_driver = Playful::File::Driver::TagDriver.new
    cur_tags = tag_driver.scan_file input_file_path
    exception_values = ['null']
    old_tags.reject { |key, value| key == :cover_art }.each do |key, value|
      unless value == cur_tags[key] || (value.blank? && cur_tags[key].blank?) || exception_values.include?(value)
        raise Task::TaskError.new "Cannot change tags, specified current tag #{key.to_s} is no longer current. " +
                                  "It's supposed to be '#{value}' but is actually '#{cur_tags[key]}'"
      end
    end
  end

  def can_scan
    unless input_file_path.nil? || completed?
      td = Playful::File::Driver::TagDriver.new
      begin
        td.scan_file(input_file_path)
      rescue Playful::File::DriverError
        errors.add('input_file_path', "Unable to scan file #{input_file_path}. Maybe the file doesn't exist or isn't an audio file?")
      end
    end
  end

  def valid_tag_names
    valid_save_tags = [:artist, :album_artist, :composer, :album, :track_title, :track_number, :track_total, :year,
                       :genre, :disc_number, :disc_total, :comment, :encoder, :lyrics, :cover_art]
    new_tags.each do |tag_name, tag_value|
      unless tag_name.class == Symbol && (tag_value.nil? || valid_save_tags.include?(tag_name))
        errors.add('new_tags', "Saving field #{tag_name.to_s} with a value other than nil is not allowed #{tag_name.class.to_s}")
      end
    end
  end

  def same_tags
    new_keys = new_tags.keys.reject { |name, value| name == :cover_art }
    old_keys = old_tags.keys.reject { |name, value| name == :cover_art }
    unless (old_keys & new_keys).length == new_keys.length
      errors.add('new_tags', "The specified new and old tags are not the same tags.")
    end
  end

  def ensure_defaults
    super()
    if new_record?
      self.old_tags = {} if old_tags.nil?
    end
  end
end

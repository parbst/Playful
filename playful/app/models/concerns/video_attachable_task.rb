require 'active_support/concern'

module VideoAttachableTask
  extend ActiveSupport::Concern

  included do
    store :store_video_clip, accessors: [:video_file_ids, :video_file_order, :video_file_imports, :video_file_delete_ids, :video_clip_changes]
    validate :valid_order_format
    validate :valid_video_files
  end

  def append_video_clips
    # append clips from inbound tasks
    import_tasks = dependee_by_class(Task::Model::BaseFile::VideoFile::Create)
    video_files = import_tasks.map { |t| t.model }
    video_files += ::BaseFile::VideoFile.find(video_file_ids) unless video_file_ids.nil?
    unless video_file_order.nil?
      video_files.sort! do |x, y|
        x_idx = video_file_order.index { |o| o[:path] == x.path || o[:id] == x.id }
        y_idx = video_file_order.index { |o| o[:path] == y.path || o[:id] == y.id }

        if !x_idx.nil? && y_idx.nil? then 1
        elsif x_idx.nil? && !y_idx.nil? then -1
        else x_idx <=> y_idx || 0
        end
      end
    end
    idx = (VideoClip.where({set: 1}).maximum(:order) || 0) + 1
    @model.video_clips += video_files.map do |vf|
      import_task = import_tasks.find {|it| it.model.id == vf.id }
      import = video_file_imports.find do |vfi|
        vfi[:video_file_id] == vf.id || !import_task.nil? && vfi[:path] == import_task.path
      end
      set = import.nil? || !import[:set].is_a?(Integer) ? 1 : import[:set]
      order = import.nil? || !import[:order].is_a?(Integer) ? idx += 1 : import[:order]
      VideoClip.ensure(video_file: vf, set: set, model: @model, order: order)
    end
    @model.save!
  end

  def resolve_clips
    @model.resolve_clips
  end

  def detach_video_clips
    unless video_file_delete_ids.nil?
      @model.video_clips.select {|ac| video_file_delete_ids.include?(ac.video_file.id) }.each(&:destroy)
    end
  end

  def update_video_clips
    unless video_clip_changes.nil?
      video_clip_changes.each do |vcc|
        video_clip = @model.video_clips.find {|vc| vc.video_file.id == vcc[:video_file_id]}
        if video_clip
          [:set, :order].each {|key| video_clip[key] = vcc[key] if vcc.has_key?(key) }
          video_clip.save!
        end
      end
    end
  end

  # params should look like {video_file_id, set, order}
  def add_video_clip_change(params)
    self.video_clip_changes ||= []
    self.video_clip_changes << params
  end

  def add_video_clip_deletion(video_file_ids)
    self.video_file_delete_ids ||= []
    self.video_file_delete_ids +=  Array(video_file_ids)
  end

  def add_video_clip_attachment(video_info, video_import_task = nil)
    self.video_file_ids ||= []
    self.video_file_imports ||= []
    if video_info.is_a?(Integer)
      self.video_file_ids << video_info
    elsif video_info.is_a?(Hash)
      if video_info[:video_file_id].nil?
        unless video_import_task.is_a?(Task::Model::BaseFile::VideoFile)
          raise 'cannot add_video_clip_attachment without a video file id or a video file import task'
        end
        depend_on(video_import_task)
      else
        self.video_file_ids << video_info[:video_file_id]
      end
      self.video_file_imports << video_info
    elsif video_info.is_a?(Array)
      video_info.each {|vi| add_video_clip_attachment(vi) }
    end
  end

  def valid_order_format
    unless video_file_order.nil? ||
        video_file_order.is_a?(Array) &&
        video_file_order.all? { |o|
          o.is_a?(Hash) &&
          o.has_shape?({video_file_id: Integer, path: String}, {allow_undefined_keys: true, allow_missing_keys: true}) &&
          (o[:video_file_id] || o[:path]) }
      errors.add('video_file_order', "Invalid format of video clips. Should be [{video_file_id: integer, path: string}]")
    end
  end

  def valid_video_files
    unless video_file_ids.nil? || video_file_ids.all? { |id| ::BaseFile::VideoFile.exists?(id) }
      errors.add('video_file_ids', "Non-existing video file #{video_file_ids.inspect}")
    end
  end

end

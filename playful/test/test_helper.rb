ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'tempfile'
require 'fileutils'
require 'flexmock/test_unit'

# since rails 4 this is the new brilliant idea...
require Rails.root.to_s + '/app/models/task/model/track/change.rb'
require Rails.root.to_s + '/app/models/task/model/track/create.rb'
require Rails.root.to_s + '/app/models/task/model/track/delete.rb'
require Rails.root.to_s + '/app/models/task/model/track/tag_and_resolve.rb'
require Rails.root.to_s + '/app/models/task/model/release/change.rb'
require Rails.root.to_s + '/app/models/task/model/release/create.rb'
require Rails.root.to_s + '/app/models/task/model/release/delete.rb'
require Rails.root.to_s + '/app/models/task/model/release/update_tracks.rb'
require Rails.root.to_s + '/app/models/task/model/season/change.rb'
require Rails.root.to_s + '/app/models/task/model/season/create.rb'
require Rails.root.to_s + '/app/models/task/model/season/delete.rb'
require Rails.root.to_s + '/app/models/task/model/episode/change.rb'
require Rails.root.to_s + '/app/models/task/model/episode/create.rb'
require Rails.root.to_s + '/app/models/task/model/episode/delete.rb'
require Rails.root.to_s + '/app/models/task/model/movie/change.rb'
require Rails.root.to_s + '/app/models/task/model/movie/create.rb'
require Rails.root.to_s + '/app/models/task/model/tv_series/create.rb'
require Rails.root.to_s + '/app/models/task/model/tv_series/change.rb'
require Rails.root.to_s + '/app/models/task/model/tv_series/resolve_episode_clips.rb'
require Rails.root.to_s + '/app/models/task/model/base_file/audio_file/delete.rb'
require Rails.root.to_s + '/app/models/task/model/base_file/audio_file/create.rb'
require Rails.root.to_s + '/app/models/task/model/base_file/image_file/create.rb'
require Rails.root.to_s + '/app/models/task/model/base_file/video_file/create.rb'
require Rails.root.to_s + '/app/models/task/model/base_file/video_file/delete.rb'
require Rails.root.to_s + '/app/models/task/file.rb'
require Rails.root.to_s + '/app/models/task/file/download.rb'

require Rails.root.to_s + '/app/models/order/file/download.rb'
require Rails.root.to_s + '/app/models/order/import/tv_series.rb'
require Rails.root.to_s + '/app/models/order/import/movie.rb'
require Rails.root.to_s + '/app/models/order/import/audio.rb'
require Rails.root.to_s + '/app/models/order/change/tv_series.rb'
require Rails.root.to_s + '/app/models/order/change/movie.rb'
require Rails.root.to_s + '/app/models/order/change/audio.rb'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def get_free_file_path
    tempfile = Tempfile.new('foo', "#{Rails.root}/test/fixtures/data/upload")
    res = tempfile.path
    tempfile.close
    tempfile.unlink
    res
  end

  def get_empty_audio_file(at_path = get_free_file_path + ".mp3")
    source_file = "#{Rails.root}/test/fixtures/data/silent.mp3"
    FileUtils.cp source_file, at_path
    at_path.gsub("\\", '/')
  end

  def get_test_video_file(at_path = get_free_file_path + ".mp4")
    source_file = "#{Rails.root}/test/fixtures/data/big_buck_bunny.mp4"
    FileUtils.cp source_file, at_path
    at_path.gsub("\\", '/')
  end

  def get_test_image_file(at_path = get_free_file_path + ".jpg")
    source_file = "#{Rails.root}/test/fixtures/data/test-all-the-things.jpg"
    FileUtils.cp source_file, at_path
    at_path.gsub("\\", '/')
  end

  def cleanup_test_dirs
    [shares(:share_upload), shares(:share_imported)].collect(&:path).each do |path|
      FileUtils.rm_r Dir.glob("#{path}/*")
    end
  end

  def prepare_files_for_fixtures
    cleanup_test_dirs
    BaseFile.where(:share_id => 2).each do |bf|
      if bf.is_a?(BaseFile::AudioFile)
        get_empty_audio_file(bf.path)
      elsif bf.is_a?(BaseFile::ImageFile)
        get_test_image_file(bf.path)
      elsif bf.is_a?(BaseFile::VideoFile)
        get_test_video_file(bf.path)
      end
    end
  end

  def get_test_imported_image_file
    scanner = Playful::Factory.file_scanner
    plain_file = get_test_image_file
    img = BaseFile::ImageFile.new
    img.update_from_scan(scanner.scan_file(plain_file))
    img.share_id = 2
    img.save!
    img.resolve_path!
    img
  end

  def get_available_file_path
    t = Tempfile.new(['rails_test', 'test'], Rails.root.join('tmp'))
    path = t.path
    t.close
    t.unlink
    path
  end

  def get_edit_tag_task_mock(path, old_tags, new_tags)
    edit_tags_task = Task::File::EditTag.new
    edit_tags_task.path = path
    edit_tags_task.old_tags = old_tags
    edit_tags_task.new_tags = new_tags
    flexmock(edit_tags_task) do |mock|
      mock.should_receive(:execute).and_return(true)
      mock.should_receive(:file_exists).and_return(true)
    end
  end

  def get_move_task_mock(base_file, from_path, to_path)
    move_task = Task::File::Move.new
    move_task.to_path = to_path
    move_task.base_file = base_file
    move_task.from_path = from_path
    flexmock(move_task) do |mock|
      mock.should_receive(:execute).and_return(true)
      mock.should_receive(:file_exists).and_return(true)
    end
  end

  def get_share_mock(name, path)
    share = Share.new
    share.name = name
    share.path = path
    flexmock(share) do |mock|
      mock.should_receive(:path_exists).and_return(true)
    end
    share.save!
    share
  end

  def get_audio_import_task_mock(path, share)
    import_task = Task::Model::BaseFile::AudioFile::Create.new
    import_task.path = path
    import_task.share = share
    flexmock(import_task) do |mock|
      mock.should_receive(:execute).and_return(true)
      mock.should_receive(:file_exists).and_return(true)
    end
  end

end

# encoding: UTF-8
require 'test_helper'

class Task::File::EditTagTest < ActiveSupport::TestCase
  fixtures :orders

  def setup
    @tag_driver = Playful::File::Driver::TagDriver.new
    @empty_audio_file = get_empty_audio_file
  end

  def teardown
    begin
      File.delete @empty_audio_file
    rescue => e
      #catch all
    end
  end

  test "task execution" do
    test_tags = {
        :artist             => "Banjo kongen",
        :album_artist       => "Supporter lenny",
        :composer           => "Uve fra baenken",
        :album              => "Styr paa den kloee",
        :track_title        => "Kloe",
        :track_number       => 1,
        :track_total        => 1,
        :year               => 2013,
        :genre              => "Rockability",
        :disc_number        => 1,
        :disc_total         => 1,
        :comment            => "Banjo og Uve er hvor det kloer",
        :encoder            => "encoder",
        :lyrics             => "lalala",
        :lyricist           => "lala manden",
        :album_artist_sort  => "?",
        :album_sort         => "?",
        :artist_sort        => "?",
        :bpm                => 120,
        :composer_sort      => "?",
        :conductor          => "Heinrich von sprelchenstein",
        :language           => "lingua franca",
        :title_sort         => "?",
        :key                => "E mol"
    }

    task = Task::File::EditTag.new
    task.order = orders(:simple)
    task.path = @empty_audio_file
    task.old_tags = Hash[test_tags.keys.collect { |v| [v, nil] }]
    task.new_tags = test_tags
    task.save!

    task.run
    assert_equal Task::Status::COMPLETED, task.status
    scan = @tag_driver.scan_file(@empty_audio_file)
    test_tags.keys.each do |k|
      assert_equal test_tags[k], scan[k]
    end
  end
end

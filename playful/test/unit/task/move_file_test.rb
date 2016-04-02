require 'test_helper'
require 'tempfile'

class Task::MoveFileTest < ActiveSupport::TestCase
  fixtures :orders

  def setup
    @tempfile = Tempfile.new('foo')
    @tempfile.close
    @new_location = @tempfile.path + ".bar"
  end

  def teardown
    begin
      File.delete @tempfile
    rescue => e
      # empty
    end
    begin
      File.delete @new_location
    rescue => e
      # empty
    end
  end

  test "task execution" do
    task = Task::File::Move.new
    task.order = orders(:simple)
    task.from_path = @tempfile
    task.to_path = @new_location
    task.save!

    task.run
    assert_equal Task::Status::COMPLETED, task.status
    assert File.exists?(task.to_path)
    assert !File.exists?(task.from_path)
  end
end

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "Execution" do
    import_order = Order::Import::Audio.new

    edit_tags_order = Order::File::EditTag.new
    edit_tags_order.tasks << get_edit_tag_task_mock('foo', { :artist => nil }, { :artist => 'something' })

    move_order = Order::File::Move.new
    move_order.tasks << get_move_task_mock(nil, 'foo', 'bar/foo')
    move_order.sequence = 1

    import_order.sub_orders << edit_tags_order
    import_order.sub_orders << move_order

    share = get_share_mock('foo', 'bar')

    import_order.tasks << get_audio_import_task_mock('bar/foo', share)

    begin
      import_order.save!
    rescue ActiveRecord::RecordInvalid => e
      import_order.tasks.each do |t|
        puts t.errors.full_messages.join(', ')
      end
      import_order.sub_orders.each do |so|
        puts so.errors.full_messages.join(', ')
      end
      raise e
    end

    import_order.run

    import_order.sub_orders.each do |so|
      assert_equal Order::Status::COMPLETED, so.status
      assert_equal import_order.id, so.parent_order.id
      so.tasks.each do |t|
        assert_equal so.id, t.order.id
      end
    end
    assert_equal Order::Status::COMPLETED, import_order.status
  end

  test "Invalid sub order" do
    invalid_sub_order = Order.new
    import_order = Order::Import::Audio.new
    import_order.sub_orders << invalid_sub_order

    assert !import_order.valid?
    assert import_order.errors.include?(:sub_orders)
  end

  test "Failed sub order" do
    failing_sub_order = Order::File::Move.new
    flexmock(failing_sub_order).should_receive(:run).and_raise(RuntimeError)

    failing_sub_order.tasks << get_move_task_mock(nil, 'foo', 'bar')

    import_order = Order::Import::Audio.new
    import_order.sub_orders << failing_sub_order
    share = get_share_mock('foo', 'bar')
    import_order.tasks << get_audio_import_task_mock('bar', share)
    import_order.save!

    import_order.run
    assert_equal Order::Status::FAILED, import_order.status
  end

  test "Test deferred" do
    deferring_sub_order = Order::File::Move.new
    flexmock(deferring_sub_order).should_receive(:execute).and_return(false)

    deferring_sub_order.tasks << get_move_task_mock(nil, 'foo', 'bar')

    import_order = Order::Import::Audio.new
    import_order.sub_orders << deferring_sub_order
    share = get_share_mock('foo', 'bar')
    import_order.tasks << get_audio_import_task_mock('bar', share)
    import_order.save!

    import_order.run
    assert_equal Order::Status::DEFERRED, import_order.status
  end
end

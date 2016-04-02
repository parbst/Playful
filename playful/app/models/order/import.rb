class Order::Import < Order

  belongs_to :task_move_file, :inverse_of => :task_import_audio, :class_name => 'Task::File::Move',
             :foreign_key => 'task_move_file_id'

#  validate :only_action_on_import_files
  class ImportError < StandardError; end

  def only_action_on_import_files
    files = []
    checked_files = []
    # visit the orders in the same order as regular processing
    if root_order?
      file_orders_in_execution_order = order_family_postorder.map {|o| o.is_a?(Order::File) }
      file_orders_in_execution_order.each do |order|
        order.task_files.each do |tf|
          # add unseen files
          files << tf[:in] unless files.include?(tf[:in])
          checked_files << tf[:in] if order.is_a?(Order::Import)

          # update file names
          files.map! {|x| x == tf[:in] ? tf[:out] : x }
          checked_files.map! {|x| x == tf[:in] ? tf[:out] : x }
        end
      end
    end

    unless (files & checked_files).length == files.length
      errors.add('sub_orders',
                 "Files #{(files - checked_files).join(', ')} are handled in sub orders but not included in import")
    end
  end

end

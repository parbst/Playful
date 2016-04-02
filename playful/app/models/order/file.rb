require 'order'

class Order::File < Order

  def task_files
    tasks.select { |t| t.is_a?(Task::File) }.map {|t| { :in => t.input_file_path, :out => t.output_file_path } }
  end

end

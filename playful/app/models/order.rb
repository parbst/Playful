require 'playful/lang/enum'

class Order < ActiveRecord::Base
  class Status < Playful::Lang::Enum
    self.add_item :PENDING,   'pending'
    self.add_item :APPROVED,  'approved'
    self.add_item :DEFERRED,  'deferred'
    self.add_item :RUNNING,   'running'
    self.add_item :FAILED,    'failed'
    self.add_item :COMPLETED, 'completed'
  end

  class OrderError < StandardError; end
  class OrderValidationError < StandardError; end

  has_many :tasks, -> { order(sequence: :asc) },
           :inverse_of => :order, :dependent => :destroy, autosave: true
  has_many :sub_orders, -> { order(sequence: :asc) },
           :inverse_of => :parent_order, :foreign_key => "parent_order_id", :class_name => "Order",
           :dependent => :destroy, autosave: true
  belongs_to :parent_order, :inverse_of => :sub_orders, :foreign_key => "parent_order_id", :class_name => "Order"
  has_many :child_orders, :inverse_of => :root_order, :foreign_key => "root_order_id", :class_name => "Order"
  belongs_to :root_order, :inverse_of => :child_orders, :foreign_key => "root_order_id", :class_name => "Order"

  before_validation :ensure_defaults, :ensure_root_order
  after_initialize :setup

  validates :root_order_id, :presence => true, :unless => 'id.nil?'
  validates :status, :inclusion => { :in => Status.values, :message => "%{value} is not a valid status" }
  validates :sequence, :uniqueness => {
    :scope => :parent_order_id,
    :message => "Some other sub order within order has already been assigned the same sequence number"
  }, :unless => "parent_order_id.nil?"
  validates :sub_orders, :presence => true, :if => "tasks.blank?"
  validates :tasks, :presence => true, :if => "sub_orders.blank?"
  validates_associated_bubbling :sub_orders
  validates_associated_bubbling :tasks
  validate :valid_sub_order_sequence, :valid_task_sequence, :valid_task_minimum, :valid_sub_order_types,
           :valid_task_types
  validate :valid_task_dependencies, :if => 'root_order?'

  def visit_postorder(&block)
    sub_orders.sort { |x,y| x.sequence <=> y.sequence }.each { |so| so.visit_postorder(&block) }
    yield self if block_given?
  end

  def order_family_postorder
    orders_in_execution_order = []
    root_order.visit_postorder {|o| orders_in_execution_order << o }
    orders_in_execution_order
  end

  def root_order?
    parent_order.nil?
  end

  def related?(other_order)
    root_order == other_order.root_order || self == other_order ||
        !root_order.nil? && !other_order.root_order.nil? && root_order.id == other_order.root_order.id
  end

  def executes_before?(other_order)
    if related?(other_order)
      orders_in_execution_order = order_family_postorder
      orders_in_execution_order.index(self) < orders_in_execution_order.index(other_order)
    else
      nil
    end
  end

  def change_status(new_status)
    transitions = {
        Order::Status::PENDING => [Order::Status::APPROVED]
    }
    is_ok = Status.include?(new_status) && transitions.has_key?(status) && transitions[status].include?(new_status)
    if is_ok
      self.status = new_status
      save!
      run!
    else
      raise OrderError.new "Illegal status change from #{status} to #{new_status}"
    end
  end

  def run!
    run
    save!
  end

  def run
    if ready_to_run?
      begin
        self.status = Status::RUNNING
        save!
        finished = execute() # factory method pattern
      rescue => msg
        self.status = Status::FAILED
        self.message = msg.message
        self.backtrace = msg.backtrace
        logger.info "Failed! #{self.message}"
        raise unless parent_order.nil?
      else
        self.status = finished ? Status::COMPLETED : Status::DEFERRED
      end
    else
      msg = "Cannot run Order which does not have status approved or deferred"
      if new_record?
        msg = "Cannot run non-persisted Order"
      elsif changed?
        msg = "Order must be persisted and unchanged before running"
      end
      raise OrderError.new msg
    end
  end

  def order_type
    self.class::TYPE
  end

  def ready_to_run?
    self_approved = [Status::APPROVED, Status::DEFERRED].include?(status)
    pending_and_parent_approved = status == Status::PENDING && !parent_order.nil? && [Status::APPROVED, Status::RUNNING, Status::COMPLETED].include?(parent_order.status)
    self_or_ancestor_approved = self_approved || (pending_and_parent_approved)
    self_or_ancestor_approved && !new_record? && !changed?
  end

  protected

  def execute
    # an order can both have sub orders and tasks. semantics are to complete sub orders before tasks
    ready, not_ready = sub_orders.partition { |so| so.ready_to_run? }
    ready.each do |so|
      begin
        so.run
      ensure
        so.save!
      end
    end

    orders_completed = sub_orders.all? { |o| o.status == Status::COMPLETED }
    if orders_completed
      tasks.each do |t|
        begin
          t.run
        ensure
          t.save
          tasks.each {|tt| tt.reload_assoc(t.id) unless tt.completed? }
        end
      end
    elsif !not_ready.empty?
      self.message = "Not all sub orders were ready to run at last execution"
    elsif !sub_orders.any? { |o| o.status == Status::DEFERRED }
      raise OrderError.new "Cannot determine Order status after processing. " +
                               "Not all sub orders are status completed but none of them are status deferred"
    end

    orders_completed
  end

  def setup
    @valid_task_types = []
    @valid_sub_order_types = []
  end

  def ensure_defaults
    if new_record?
      if sequence.nil?
        self.sequence = 0
      end
      if status.nil?
        self.status = Status::PENDING
      end
      tasks.each_with_index do |t, idx|
        t.sequence = idx if t.sequence.nil?
        t.order = self if t.order.nil?
      end
    end
  end

  def task_input_files
    get_task_files.map { |tf| tf[:in] }
  end

  def task_output_files
    get_task_files.map { |tf| tf[:out] }
  end

  # validations

  def valid_sub_order_types
    @valid_sub_order_types ||= []
    unless sub_orders.all? { |t| @valid_sub_order_types.include?(t.order_type) }
      sub_order_types = sub_orders.map {|o| o.order_type}
      errors.add('sub_orders',
                 "Only sub orders of type #{@valid_sub_order_types.join(', ')} may " +
                 "be present in an order of type #{order_type}. " +
                 "Actual orders were #{sub_order_types.join(', ')}")
    end
  end

  def valid_sub_order_sequence
    sequence_numbers = sub_orders.map {|so| so.sequence }
    if sequence_numbers.uniq.length != sequence_numbers.length
      errors.add('sub_orders', "not having unique sequence numbers")
    end
  end

  def valid_task_types
    @valid_task_types ||= []
    invalid_tasks = tasks.reject { |t| @valid_task_types.include?(t.task_type) }
    unless invalid_tasks.empty?
      errors.add('sub_orders', "Only tasks of type #{@valid_task_types.join(', ')} may " +
          "be present in an order of type #{order_type}. Invalid tasks had type #{invalid_tasks.map{ |t| t.class::TYPE }.inspect}")
    end
  end

  def valid_task_sequence
    sequence_numbers = tasks.map {|t| t.sequence }
    if sequence_numbers.uniq.length != sequence_numbers.length
      errors.add('tasks', "not having unique sequence numbers")
    end
  end

  def valid_task_minimum
    @valid_task_minimum ||= 1
    unless tasks.length >= @valid_task_minimum
      errors.add('tasks', "Minimum number of tasks for #{order_type} is #{@valid_task_minimum.to_s}")
    end
  end

  def ensure_root_order
    if root_order.nil?
      if parent_order.nil?
        self.root_order = self
      else
        root = parent_order
        until root.parent_order.nil?
          root = root.parent_order
        end
        self.root_order = root
      end
    end
  end

  def valid_task_dependencies
    if root_order?
      logger.info "valid_task_dependencies"
      dependencies = order_family_postorder.map {|o| o.tasks.map {|t| t.dependee_tasks_association }.flatten }.flatten
      dependencies.each do |assoc|
        msg = "Task #{assoc.dependent_task.task_type} depends on task " +
            "#{assoc.dependee_task.task_type} but they are either " +
            "not included in the same order family or dependent order executes earlier"
        unless assoc.dependee_task.executes_before?(assoc.dependent_task)
          errors.add(:sub_orders, msg)
        end
      end
    end
  end

end

require 'order/file'
require 'playful/lang/enum'

class Task < ActiveRecord::Base
  attr_accessor :valid_task_dependees, :valid_task_dependees_dynamic

  belongs_to :order, :inverse_of => :tasks
  has_many :dependent_tasks_association, :class_name => 'TaskDependency', :foreign_key => 'dependee_task_id', :dependent => :nullify, :autosave => false
  has_many :dependent_tasks, :through => :dependent_tasks_association, :source => :dependent_task, :autosave => false
  has_many :dependee_tasks_association, :class_name => 'TaskDependency', :foreign_key => 'dependent_task_id', :dependent => :destroy, :autosave => true
  has_many :dependee_tasks, :through => :dependee_tasks_association, :source => :dependee_task, :autosave => false
  self.inheritance_column = 'sti_type'

  before_validation :ensure_defaults, :on => :create
#  before_save :ensure_order_id
  after_save :update_dependent_tasks_assoc
  after_initialize :setup
  validates :order_id, :presence => true, :if => "order.nil?"
  validates :order, :presence => true, :if => "order_id.nil?"
  validate :abstract_task

  class TaskError < StandardError; end

  class Status < Playful::Lang::Enum
    self.add_item :PENDING,   'pending'
    self.add_item :RUNNING,   'running'
    self.add_item :FAILED,    'failed'
    self.add_item :COMPLETED, 'completed'
  end

  validates :status, :inclusion => { :in => Status.values, :message => "%{value} is not a valid status" }
  validates_associated_bubbling :dependee_tasks_association

  def reload_assoc(task_id)
    dependent_tasks.select {|dt| dt.id == task_id }.each(&:reload)
    dependent_tasks_association.map {|dta| dta.dependent_task }.select { |dt| dt.id == task_id }.each(&:reload)
    dependee_tasks_association.map {|dta| dta.dependee_task }.select {|dt| dt.id == task_id }.each(&:reload)
    dependee_tasks.select {|dt| dt.id == task_id}.each(&:reload)
  end

  def ensure_defaults
    if new_record?
      self.status = Status::PENDING if status.nil?
    end
  end

  def task_type
    self.class::TYPE
  end

  def run
    if self.status == Status::PENDING
      begin
        self.status = Status::RUNNING
        execute # factory method pattern
      rescue => err
        self.message = err.message
        self.backtrace = err.backtrace
        self.status = Status::FAILED
        raise
      else
        self.status = Status::COMPLETED
      end
    else
      raise TaskError.new 'Cannot run Task which is not pending'
    end
  end

  def execute
    raise NotImplementedError.new "Class #{self.class.name} deriving from Task must implement the execute method"
  end

  def executes_before?(other_task)
    order.related?(other_task.order) && (order.executes_before?(other_task.order) || order == other_task.order && other_task.sequence > sequence)
  end

  def dependee_by_class(clazz)
    in_mem = dependee_tasks_association.select { |dta| dta.dependee_task.is_a?(clazz) }.map { |dta| dta.dependee_task }
    in_db = dependee_tasks_association.load.select { |dta| dta.dependee_task.is_a?(clazz) }.map { |dta| dta.dependee_task }
    in_mem_ids = in_mem.map { |dt| dt.id }.compact
    all = in_mem + in_db.select { |dt| !in_mem_ids.include?(dt.id) }
    all.sort { |a,b| a.sequence <=> b.sequence }
  end

  def dependent_by_class(clazz)
    in_mem = dependent_tasks_association.select { |dta| dta.dependent_task.is_a?(clazz) }.map { |dta| dta.dependent_task }
    in_db = dependent_tasks_association.load.select { |dta| dta.dependent_task.is_a?(clazz) }.map { |dta| dta.dependent_task }
    in_mem_ids = in_mem.map { |dt| dt.id }.compact
    all = in_mem + in_db.select { |dt| !in_mem_ids.include?(dt.id) }
    all.sort { |a,b| a.sequence <=> b.sequence }
  end

  def dependee_by_name(name)
    unless @valid_task_dependees.keys.include?(name)
      raise "Sought for dependee by name (#{name.to_s}) which is not approved as a dependency name by the class (#{self.class.to_s}) itself!"
    end
    in_mem = dependee_tasks_association.select { |dta| dta. name.to_s == name.to_s }.first
    in_mem.reload unless in_mem.nil? || in_mem.new_record? || in_mem.changed?
    in_db = dependee_tasks_association.find_by_name name.to_s
    a = in_mem || in_db
    a.dependee_task unless a.nil?
  end

  def depend_on(args)
    args = Array(args) if args.is_a?(Task)
    if args.is_a?(Array)
      args.each do |task|
        assoc = dependee_tasks_association.build(dependee_task: task, dependent_task: self)
        task.dependent_tasks_association << assoc
      end
    elsif args.is_a?(Hash)
      args.each do |name, task|
        a = dependee_by_name name
        if a.nil?
          assoc = dependee_tasks_association.build(name: name.to_s, dependee_task: task, dependent_task: self)
          task.dependent_tasks_association << assoc
        else
          a.dependee_task = task
        end
      end
    end

    self
  end

  def completed?
    status == Status::COMPLETED
  end

  def failed?
    status == Status::FAILED
  end

  def pending?
    status == Status::PENDING
  end

  def running?
    status == Status::RUNNING
  end

  protected

  def setup
    @valid_task_dependees ||= {} # as name => task class
    @valid_task_dependees_dynamic ||= []
  end

  # validations

  def file_exists
    errors.add('from_path', "No such file '#{path}'") if base_file.nil? && !File.file?(path)
  end

  # hooks

  def update_dependent_tasks_assoc
    logger.info "update_dependent_tasks_assoc for #{id} #{task_type} #{dependent_tasks_association.length} associations"
    dependent_tasks_association.select { |dta| dta.dependee_task_id.nil? }.each do |dta|
      dta.dependee_task = self
      # seems the dependent task is already saved, make an exception and save this dependency
      dta.save! unless dta.dependent_task.nil? || dta.dependent_task.new_record?
    end
  end

  def ensure_order_id
    logger.info "task #{task_type} #{id} ensure_order_id #{order.nil?} " + (order.nil? ? '' : "#{order.id}")
    self.order_id = order.id unless order.nil?
  end

  def abstract_task
    errors.add('type', "Abstract type cannot be created. A standalone task must define it's own TYPE") unless defined? self.class::TYPE # constants.include?(TYPE)
  end

end

require 'task/file'
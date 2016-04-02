class TaskDependency < ActiveRecord::Base
  belongs_to :dependent_task, :class_name => 'Task'
  belongs_to :dependee_task, :class_name => 'Task'

  validate :valid_dependency, :if => :have_tasks_in_mem?
  validate :unique_dependency

  protected

  # validations

  def have_tasks_in_mem?
    !dependent_task.nil? && !dependee_task.nil?
  end

  def both_tasks_saved?
    !dependent_task_id.nil? && !dependee_task_id.nil?
  end

  def valid_dependency
    vtd_named = dependent_task.valid_task_dependees
    vtd_dyn = dependent_task.valid_task_dependees_dynamic
    msg = "invalid task type used for dependency! #{dependent_task.class.to_s} " +
        "allows #{vtd_named.inspect} and #{vtd_dyn.inspect} for dynamic dependencies but dependee was " +
        "#{dependee_task.class.to_s}"
    named_dependencies_valid = !name.nil? && !vtd_named[name.to_sym].nil? && dependee_task.is_a?(vtd_named[name.to_sym])
    dyn_dependencies_valid = name.nil? && vtd_dyn.any? { |clazz| dependee_task.is_a?(clazz) }
    errors.add('dependee_task', msg) unless named_dependencies_valid || dyn_dependencies_valid
  end

  def dependee_exec_before_dependent
    msg = "Task #{dependent_task.id}, #{dependent_task.task_type} depends on task #{dependee_task.id}, #{dependee_task.task_type} but #{dependee_task.id} is either " +
        "not included in the same order family or is executed after #{dependent_task.id}."
    [:dependent_task, :dependee_task].each do |attr_name|
      errors.add(attr_name,  msg)
    end unless dependee_task.executes_before?(dependent_task)
  end

  def unique_dependency
    unless name.nil?
      unique = dependent_task.dependee_tasks_association.select { |a| a.name == name }.length < 2

      unless unique
        errors.add(:dependency,  "Named dependencies must be unique")
      end
    end
    similar = dependent_task.dependee_tasks_association.select do |dta|
      dta.dependee_task == dependee_task && dta.name == name
    end
    if similar.length > 1
      errors.add(:dependency,  "Dublet dynamic dependency #{self.inspect}")
    end
  end
end

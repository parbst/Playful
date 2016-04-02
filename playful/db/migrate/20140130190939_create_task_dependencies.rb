class CreateTaskDependencies < ActiveRecord::Migration
  def change
    create_table :task_dependencies do |t|
      t.column :name, :string
      t.references :dependee_task
      t.references :dependent_task
      t.timestamps
    end
    add_index :task_dependencies, [:name, :dependee_task_id, :dependent_task_id], :unique => true, :name => 'task_dependencies_unique'
  end
end

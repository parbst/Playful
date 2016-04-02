class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.column :type, :string, :limit => 50

      t.column :root_order_id, :integer
      t.column :parent_order_id, :integer
      t.column :status, :string, :limit => 50, :null => false
      t.column :message, :string, :limit => 1024
      t.column :backtrace, :text
      t.column :sequence, :integer, :null => false

      t.timestamps
    end
  end
end

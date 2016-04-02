class CreateShares < ActiveRecord::Migration
  def change
    #, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8'
    create_table :shares do |t|
      t.column :path,         :string,  :limit => 1024, :null => false
      t.column :name,         :string,  :limit => 512,  :null => false
      t.column :description,  :string,  :limit => 2048, :null => true

      t.timestamps
    end
  end
end

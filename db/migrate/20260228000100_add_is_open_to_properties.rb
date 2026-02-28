class AddIsOpenToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :is_open, :boolean, null: false, default: true
    add_index :properties, :is_open
  end
end

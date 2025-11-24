class AddColsRowsToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :col_names, :string
    add_column :items, :row_names, :string
  end
end

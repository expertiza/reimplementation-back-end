class AddTextareaWidthToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :textarea_width, :integer
    add_column :items, :textarea_height, :integer
    add_column :items, :textbox_width, :integer
  end
end

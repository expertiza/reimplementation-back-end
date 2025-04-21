class AddSkippableToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :skippable, :boolean, default: false, null: false
  end
end

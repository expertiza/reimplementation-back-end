class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :time_zone, :string
    add_column :users, :language, :string
    add_column :users, :can_show_actions, :boolean
  end
end

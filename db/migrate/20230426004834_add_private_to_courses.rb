class AddPrivateToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :private, :boolean
  end
end

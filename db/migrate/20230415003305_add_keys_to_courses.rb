class AddKeysToCourses < ActiveRecord::Migration[7.0]
  def change
    add_reference :courses, :institution, null: false, foreign_key: true
  end
end

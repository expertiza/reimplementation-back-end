class AddIndexToCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :courses, :instructor_id, name: "fk_course_users"
  end
end

class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :title
      t.integer :instructor_id
      t.string :directory_path
      t.text :info

      t.timestamps
    end
  end
end

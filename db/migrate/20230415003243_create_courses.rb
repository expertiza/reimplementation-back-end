class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :directory_path
      t.text :info
      t.boolean :private, default: false

      t.timestamps
    end
    add_reference :courses, :instructor, foreign_key: { to_table: :users }, null: false
    add_reference :courses, :institution, foreign_key: true, null: false
    add_index :courses, :instructor, name: "fk_course_users"
  end
end

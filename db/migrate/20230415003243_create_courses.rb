class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :directory_path
      t.text :info
      t.boolean :private, default:false
      t.integer :instructor_id

      t.timestamps
    end
  end
end

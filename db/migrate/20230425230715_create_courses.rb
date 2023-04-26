class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.column 'title', :string
      t.column 'instructor_id', :integer
      t.column 'directory_path', :string
      t.column 'info', :text
      t.column 'survey_distribution_id', :string
      t.timestamps
    end
  end
end
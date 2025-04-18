class AddCourseIdToTeams < ActiveRecord::Migration[8.0]
  def change
    add_reference :teams, :course, foreign_key: true
  end
end

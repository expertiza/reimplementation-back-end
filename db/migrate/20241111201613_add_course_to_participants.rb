class AddCourseToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_reference :participants, :course, null: false, foreign_key: true
  end
end

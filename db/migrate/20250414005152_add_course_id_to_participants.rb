class AddCourseIdToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :course, foreign_key: true
  end
end

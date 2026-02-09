# frozen_string_literal: true

class RemoveCourseIdFromAssignments < ActiveRecord::Migration[7.0]
  def change
    remove_column :assignments, :course_id, :integer
  end
end

# frozen_string_literal: true

class RemoveInstructorIdFromAssignments < ActiveRecord::Migration[7.0]
  def change
    remove_column :assignments, :instructor_id, :integer
  end
end

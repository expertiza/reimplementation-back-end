# frozen_string_literal: true

class AddCourseToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_reference :assignments, :course, null: true, foreign_key: true
  end
end

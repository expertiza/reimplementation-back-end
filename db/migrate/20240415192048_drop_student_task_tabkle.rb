# frozen_string_literal: true

class DropStudentTaskTabkle < ActiveRecord::Migration[7.0]
  def change
    drop_table :student_tasks
  end
end

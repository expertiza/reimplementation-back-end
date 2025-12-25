# frozen_string_literal: true

class CreateStudentTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :student_tasks do |t|
      t.references :assignment, null: false, foreign_key: true
      t.string :current_stage
      t.references :participant, null: false, foreign_key: true
      t.datetime :stage_deadline
      t.string :topic

      t.timestamps
    end
  end
end

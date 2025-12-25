# frozen_string_literal: true

class AddUsedInRoundToAssignmentQuestionnaire < ActiveRecord::Migration[7.0]
  def change
    add_column :assignment_questionnaires, :used_in_round, :integer, null: true
  end
end

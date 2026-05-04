# frozen_string_literal: true

# E2619: Add quiz_questionnaire_id to teams so each submitting team owns their quiz questionnaire.
# This replaces the assignment_questionnaires-based lookup (which required instructor setup).
class AddQuizQuestionnaireIdToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :quiz_questionnaire_id, :integer, null: true, default: nil
    add_index  :teams, :quiz_questionnaire_id
  end
end

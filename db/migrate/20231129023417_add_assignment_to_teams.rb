# frozen_string_literal: true

class AddAssignmentToTeams < ActiveRecord::Migration[7.0]
  def change
    add_reference :teams, :assignment, null: false, foreign_key: true
  end
end

# frozen_string_literal: true

class AddHasTeamsToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :has_teams, :boolean, default: false
  end
end

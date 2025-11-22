# frozen_string_literal: true

class AddVaryByRoundToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :vary_by_round, :boolean, default: false, null: false
  end
end

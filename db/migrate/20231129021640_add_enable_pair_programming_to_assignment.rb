class AddEnablePairProgrammingToAssignment < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :enable_pair_programming, :boolean
  end
end

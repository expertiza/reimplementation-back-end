class AddApplyLatePolicyToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :apply_late_policy, :boolean, default: false, null: false
  end
end



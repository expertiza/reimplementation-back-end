class AdjustDutyLimits < ActiveRecord::Migration[8.0]
  def change
    remove_column :duties, :max_members_for_duty, :integer
    add_column :assignments_duties, :max_members_for_duty, :integer, default: 1
  end
end

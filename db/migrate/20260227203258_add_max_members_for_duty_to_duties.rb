class AddMaxMembersForDutyToDuties < ActiveRecord::Migration[8.0]
  def change
    add_column :duties, :max_members_for_duty, :integer
  end
end

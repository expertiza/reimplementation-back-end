class AddMaxMembersForDutyToDuties < ActiveRecord::Migration[8.0]
  def change
    add_column :duties, :max_members_for_duty, :integer unless column_exists?(:duties, :max_members_for_duty)
  end
end

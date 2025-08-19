class ChangeTeamsTypeNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :teams, :type, false
  end
end

class AddRoundAndVersionNumToResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :responses, :round, :integer
    add_column :responses, :version_num, :integer
  end
end

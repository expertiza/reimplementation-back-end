class AddRoundToResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :responses, :round, :integer
  end
end

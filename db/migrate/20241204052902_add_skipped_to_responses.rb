class AddSkippedToResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :responses, :skipped, :boolean, default: false
  end
end

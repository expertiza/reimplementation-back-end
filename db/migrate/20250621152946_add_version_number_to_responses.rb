class AddVersionNumberToResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :responses, :version_num, :integer
  end
end

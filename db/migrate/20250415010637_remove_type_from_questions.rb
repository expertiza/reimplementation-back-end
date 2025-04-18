class RemoveTypeFromQuestions < ActiveRecord::Migration[8.0]
  def change
    remove_column :questions, :type, :string
  end
end

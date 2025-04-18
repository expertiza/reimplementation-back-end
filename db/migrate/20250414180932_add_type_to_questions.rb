class AddTypeToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :type, :string
  end
end

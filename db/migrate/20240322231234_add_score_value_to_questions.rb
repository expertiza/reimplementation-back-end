class AddScoreValueToQuestions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists? :questions, :score_value
      add_column :questions, :score_value, :integer
    end
  end
end

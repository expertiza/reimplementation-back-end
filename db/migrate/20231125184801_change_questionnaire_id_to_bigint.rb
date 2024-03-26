class ChangeQuestionnaireIdToBigint < ActiveRecord::Migration[7.0]
  def up
    change_column :questions, :questionnaire_id, :bigint, null: false
  end

  def down
    change_column :questions, :questionnaire_id, :integer
  end
end

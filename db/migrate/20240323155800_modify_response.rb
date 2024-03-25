class ModifyResponse < ActiveRecord::Migration[7.0]
  def change
    add_reference :responses, :response_map, foreign_key: true
    add_reference :responses, :question, foreign_key: true
    add_column :responses, :submitted_answer, :string
  end
end

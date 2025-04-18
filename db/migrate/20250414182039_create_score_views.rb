class CreateScoreViews < ActiveRecord::Migration[8.0]
  def change
    create_table :score_views do |t|
      t.integer :question_weight  # No need to specify limit: 10
      t.string :type, limit: 255
      t.integer :q1_id
      t.string :q1_name, limit: 255
      t.integer :q1_instructor_id
      t.boolean :q1_private, default: false
      t.integer :q1_min_question_score
      t.integer :q1_max_question_score
      t.datetime :q1_created_at
      t.datetime :q1_updated_at
      t.string :q1_type, limit: 255
      t.string :q1_display_type, limit: 255
      t.integer :ques_id
      t.integer :ques_questionnaire_id
      t.integer :s_id
      t.integer :s_question_id
      t.integer :s_score
      t.text :s_comments
      t.integer :s_response_id

      t.timestamps
    end
  end
end

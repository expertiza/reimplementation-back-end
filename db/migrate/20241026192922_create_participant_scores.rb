class CreateParticipantScores < ActiveRecord::Migration[7.0]
  def change
    create_table :participant_scores do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :score
      t.integer :total_score
      t.integer :round

      t.timestamps
    end
  end
end

class AddAssignmentToSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    add_reference :sign_up_topics, :assignment, null: false, foreign_key: true
  end
end

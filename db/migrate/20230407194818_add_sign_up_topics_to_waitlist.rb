class AddSignUpTopicsToWaitlist < ActiveRecord::Migration[7.0]
  def change
    add_reference :waitlists, :sign_up_topic, null: false, foreign_key: true
  end
end

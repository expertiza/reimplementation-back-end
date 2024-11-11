class CreateSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :sign_up_topics do |t|

      t.timestamps
    end
  end
end

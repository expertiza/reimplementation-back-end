class CreateAccountRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :account_requests do |t|
      t.string :username
      t.string :full_name
      t.string :email
      t.string :status
      t.text :introduction

      t.timestamps
    end
  end
end

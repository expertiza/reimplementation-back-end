class CreateAccountRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :account_requests do |t|
      t.string :name
      t.string :fullname
      t.string :email
      t.string :status
      t.text :self_introduction

      t.timestamps
    end
  end
end

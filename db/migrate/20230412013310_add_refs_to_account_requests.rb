class AddRefsToAccountRequests < ActiveRecord::Migration[7.0]
  def change
    add_reference :account_requests, :role, null: false, foreign_key: true
    add_reference :account_requests, :institution, null: false, foreign_key: true
  end
end

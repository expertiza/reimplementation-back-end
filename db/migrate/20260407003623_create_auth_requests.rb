class CreateAuthRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_requests do |t|
      t.string :state
      t.string :nonce
      t.string :code_verifier
      t.string :provider

      t.timestamps
    end
    add_index :auth_requests, :state
  end
end

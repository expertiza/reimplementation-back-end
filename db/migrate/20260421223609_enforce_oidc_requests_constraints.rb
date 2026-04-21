class EnforceOidcRequestsConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :oidc_requests, :state, false
    change_column_null :oidc_requests, :nonce, false
    change_column_null :oidc_requests, :code_verifier, false
    change_column_null :oidc_requests, :provider, false
    change_column_null :oidc_requests, :username, false

    remove_index :oidc_requests, :state
    add_index :oidc_requests, :state, unique: true
  end
end

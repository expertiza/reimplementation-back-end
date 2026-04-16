class AddUsernameToOidcRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :oidc_requests, :username, :string
  end
end

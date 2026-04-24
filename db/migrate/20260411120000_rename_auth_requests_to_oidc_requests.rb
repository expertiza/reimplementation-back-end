class RenameAuthRequestsToOidcRequests < ActiveRecord::Migration[8.0]
  def up
    rename_table :auth_requests, :oidc_requests

    if index_name_exists?(:oidc_requests, 'index_auth_requests_on_state')
      rename_index :oidc_requests, 'index_auth_requests_on_state', 'index_oidc_requests_on_state'
    end
  end

  def down
    rename_table :oidc_requests, :auth_requests

    if index_name_exists?(:auth_requests, 'index_oidc_requests_on_state')
      rename_index :auth_requests, 'index_oidc_requests_on_state', 'index_auth_requests_on_state'
    end
  end
end

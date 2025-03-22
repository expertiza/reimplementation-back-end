require 'swagger_helper'
require 'json_web_token'

RSpec.describe "Responses API", type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:adm) {
    User.create(
      name: "adma",
      password_digest: "password",
      role_id: @roles[:admin].id,
      full_name: "Admin A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: adm.id}) }
  let(:Authorization) { "Bearer #{token}" }
end

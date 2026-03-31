require 'swagger_helper'

RSpec.describe 'api/v1/import', type: :request do
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

  path '/import/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'class name'

    let(:id) { "User" }

    get('Show Class Fields for Import') do
      tags 'Import'
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          pp data
          expect(data["mandatory_fields"].length).to eq(4)
          expect(data).to have_key("optional_fields")
          expect(data).to have_key('external_fields')
          expect(data["available_actions_on_dup"].length).to eq(3)
        end
      end
    end
  end
end

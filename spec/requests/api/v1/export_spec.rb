# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Export API', type: :request do
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

  path '/export/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'class name'

    let(:id) { "User" }

    get('Show Class Fields for Export') do
      tags 'Export'
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
        end
      end
    end
  end
end

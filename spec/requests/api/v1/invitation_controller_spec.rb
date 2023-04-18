require 'swagger_helper'

RSpec.describe 'Roles API', type: :request do

  path '/api/v1/invitations' do
    get('list invitations') do
      tags 'Invitations'
      produces 'application/json'

      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Impersonate Controller', type: :request do

  path '/api/v1/impersonate' do
    parameter name: 'impersonate', in: :path, type: :string, description: 'impersonate'

    post('impersonate impersonate') do
      tags 'Impersonate'
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

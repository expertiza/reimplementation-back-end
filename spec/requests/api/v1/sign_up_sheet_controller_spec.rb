require 'swagger_helper'

RSpec.describe 'SignUpSheetController API', type: :request do

path '/api/v1/sign_up_sheet_controller' do


    get('New Sign Up Sheet Params') do
      tags 'SignUpSheet'
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

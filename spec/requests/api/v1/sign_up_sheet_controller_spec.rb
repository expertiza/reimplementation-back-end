require 'swagger_helper'

RSpec.describe 'SignUpSheetController API', type: :request do

  path '/api/v1/sign_up_sheet' do

    get('check if sheet can be access via index') do
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

  path '/api/v1/sign_up_sheet/delete_signup' do
    get('list the sheet') do
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


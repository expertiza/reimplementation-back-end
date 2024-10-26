require 'swagger_helper'

RSpec.describe describe 'Grades API', type: :request do
  path '/api/v1/grades/{action}/action_allowed' do
    parameter name: 'action', in: :path, type: :string, description: 'the action the user wishes to perform'
    get('action_allowed') do

    end

  end
end
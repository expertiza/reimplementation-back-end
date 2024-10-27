require 'swagger_helper'

RSpec.describe 'Grades API', type: :request do
  before do
    @role = Role.find_or_create_by(name: 'admin')
    @institution = Institution.find_or_create_by(name: 'Test Institution')
    @user = create(:user, role: @role, institution: @institution)
    @course = create(:course, instructor: @user)
    @assignment = create(:assignment, instructor: @user, course: @course)
  end

  before(:each) do
    post '/login', params: { user_name: @user.name, password: 'password' }
    @token = JSON.parse(response.body)['token']
  end

  path '/api/v1/grades/{action}/action_allowed' do
    parameter name: 'action', in: :path, type: :string, description: 'the action the user wishes to perform'
    parameter name: 'id', in: :query, type: :integer, description: 'Assignment ID', required: true

    let(:action) { 'view' }
    let(:id) { @assignment.id }

    get('action_allowed') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }
      response(200, 'successful') do
        run_test!
      end
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Student Teams Controller', type: :request do
  path '/api/v1/student_teams/hellothere' do
    get('some json') do
      tags 'Roles'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:mock_assignment_team) { double("AssignmentTeam", name: 'example_team') }

        before do
          # Stub the call to AssignmentTeam.find_by and return the mock object
          allow(AssignmentTeam).to receive(:find_by).with(name: 'example_team').and_return(mock_assignment_team)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        it 'returns team details when the team is found' do
          run_test!
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['team_name']).to eq('example_team')
          expect(JSON.parse(response.body)['status']).to eq('found')
        end
      end
    end
  end

  path '/api/v1/student_teams' do
    get('some json') do
      tags 'Roles'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'successful') do
        # let(:mock_assignment_team) { double("AssignmentTeam", name: 'example_team') }

        # before do
        #   # Stub the call to AssignmentTeam.find_by and return the mock object
        #   allow(AssignmentTeam).to receive(:find_by).with(name: 'example_team').and_return(mock_assignment_team)
        # end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        it 'returns team details when the team is found' do
          run_test!
          expect(response.status).to eq(200)
          # expect(JSON.parse(response.body)['team_name']).to eq('example_team')
          # expect(JSON.parse(response.body)['status']).to eq('found')
        end
      end
    end
  end
end

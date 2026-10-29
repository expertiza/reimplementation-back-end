# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'ReviewMappings Request Review API', type: :request do
  include_context 'request review student setup'

  # -------------------------------------------------------------------------
  # POST /review_mappings/request_review
  # -------------------------------------------------------------------------
  path '/review_mappings/request_review' do
    post 'Student requests a dynamic review assignment' do
      tags 'ReviewMappings'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :assignment_id,  in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: :body,           in: :body,   schema: {
        type: :object,
        properties: {
          topic_id: { type: :integer },
          i_dont_care: { type: :boolean }
        }
      }

      context 'assignment without topics' do
        let!(:reviewee_team) do
          AssignmentTeam.create!(name: 'Reviewee No-Topic Team', parent_id: assignment.id)
        end

        response '200', 'creates mapping when no topics and reviewer has capacity' do
          let(:assignment_id) { assignment.id }
          let(:body)          { {} }

          before do
            mapping = ReviewResponseMap.create!(
              reviewer_id: participant.id,
              reviewee_id: reviewee_team.id,
              reviewed_object_id: assignment.id
            )
            allow_any_instance_of(ReviewMappingHandler).to receive(:assign_dynamically).and_return(mapping)
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('ok')
            expect(data).to have_key('mapping_id')
          end
        end
      end

      context 'assignment with topics and can_choose_topic_to_review' do
        before { assignment.update!(can_choose_topic_to_review: true, has_teams: true) }

        let!(:topic) do
          ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'Choosable', max_choosers: 3)
        end

        response '422', 'returns error when topic required but not provided' do
          let(:assignment_id) { assignment.id }
          let(:body)          { {} }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['error']).to include('No topic selected')
          end
        end
      end

      response '422', 'returns error when review limit reached' do
        before do
          assignment.update!(num_reviews_allowed: 1)
          team = AssignmentTeam.create!(name: 'Limit Test Team', parent_id: assignment.id)
          ReviewResponseMap.create!(reviewer_id: participant.id, reviewee_id: team.id,
                                    reviewed_object_id: assignment.id)
        end

        let(:assignment_id) { assignment.id }
        let(:body)          { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('cannot do more than')
        end
      end

      response '403', 'non-participant cannot request review' do
        let!(:other_student) do
          User.create!(name: 'rrv_other', password_digest: 'password',
                       role_id: @roles[:student].id, full_name: 'Other RRV Student',
                       email: 'rrv_other@example.com')
        end
        let(:token)         { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }
        let(:body)          { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('You are not a participant in this assignment')
        end
      end

      response '401', 'missing token returns Not Authorized' do
        let(:Authorization) { 'Bearer ' }
        let(:assignment_id) { assignment.id }
        let(:body)          { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end
end

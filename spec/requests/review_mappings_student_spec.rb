# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'ReviewMappings Eligible Topics API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: 'rm_instructor',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'RM Instructor',
      email: 'rm_instructor@example.com'
    )
  end

  let!(:student) do
    User.create!(
      name: 'rm_student',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'RM Student',
      email: 'rm_student@example.com'
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'RM Assignment',
      instructor: instructor,
      review_assignment_strategy: 'Auto-Selected',
      review_topic_threshold: 1,
      has_teams: true
    )
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let(:token)         { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # -------------------------------------------------------------------------
  # GET /review_mappings/eligible_topics
  # -------------------------------------------------------------------------
  path '/review_mappings/eligible_topics' do
    get 'List topics eligible for dynamic review selection' do
      tags 'ReviewMappings'
      produces 'application/json'
      parameter name: :assignment_id,  in: :query,  type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns eligible topics within K threshold' do
        let!(:topic_a) do
          ProjectTopic.create!(
            assignment_id: assignment.id,
            topic_name: 'Topic A',
            max_choosers: 3
          )
        end

        let!(:topic_b) do
          ProjectTopic.create!(
            assignment_id: assignment.id,
            topic_name: 'Topic B',
            max_choosers: 3
          )
        end

        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('eligible_topics')
          expect(data).to have_key('threshold')
          expect(data).to have_key('min_review_count')
          expect(data['threshold']).to eq(1)
          topic_ids = data['eligible_topics'].map { |t| t['id'] }
          expect(topic_ids).to include(topic_a.id, topic_b.id)
        end
      end

      response '422', 'returns error when assignment has no topics' do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('This assignment does not have topics')
        end
      end

      response '403', 'non-participant cannot access eligible topics' do
        let!(:other_student) do
          User.create!(
            name: 'rm_other',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other RM Student',
            email: 'rm_other@example.com'
          )
        end
        let(:token)         { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('You are not a participant in this assignment')
        end
      end

      response '401', 'missing token returns Not Authorized' do
        let(:Authorization) { 'Bearer ' }
        let(:assignment_id)   { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end
end

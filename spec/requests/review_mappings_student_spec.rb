# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'ReviewMappings Student API', type: :request do
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
      review_topic_threshold: 1
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
          expect(data['error']).to eq('Not a participant')
        end
      end

      response '401', 'missing token returns Not Authorized' do
        let(:'Authorization') { 'Bearer ' }
        let(:assignment_id)   { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end

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
          topic_id:    { type: :integer },
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
            # Stub LeastReviewedSubmissionStrategy to return a valid mapping
            mapping = ReviewResponseMap.create!(
              reviewer_id:        participant.id,
              reviewee_id:        reviewee_team.id,
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
        let!(:topic) do
          ProjectTopic.create!(
            assignment_id: assignment.id,
            topic_name: 'Choosable Topic',
            max_choosers: 3
          )
        end

        let!(:topic_assignment) do
          assignment.update!(can_choose_topic_to_review: true)
          assignment
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
          reviewee_team = AssignmentTeam.create!(name: 'Limit Test Team', parent_id: assignment.id)
          ReviewResponseMap.create!(
            reviewer_id:        participant.id,
            reviewee_id:        reviewee_team.id,
            reviewed_object_id: assignment.id
          )
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
          User.create!(
            name: 'rm_other2',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other RM Student2',
            email: 'rm_other2@example.com'
          )
        end
        let(:token)         { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }
        let(:body)          { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not a participant')
        end
      end

      response '401', 'missing token returns Not Authorized' do
        let(:'Authorization') { 'Bearer ' }
        let(:assignment_id)   { assignment.id }
        let(:body)            { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end
end

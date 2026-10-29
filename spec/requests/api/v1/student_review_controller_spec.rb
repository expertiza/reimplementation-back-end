# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentReview API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: 'sr_instructor',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'SR Instructor',
      email: 'sr_instructor@example.com'
    )
  end

  let!(:student) do
    User.create!(
      name: 'sr_student',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'SR Student',
      email: 'sr_student@example.com'
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'SR Assignment',
      instructor: instructor,
      review_assignment_strategy: 'Auto-Selected'
    )
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let!(:reviewee_team) do
    AssignmentTeam.create!(name: 'Reviewee Team', parent_id: assignment.id)
  end

  let(:token)         { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # -------------------------------------------------------------------------
  # GET /assignments/:assignment_id/student_review/list
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/student_review/list' do
    get 'List of reviews assigned to the current student' do
      tags 'StudentReview'
      produces 'application/json'
      parameter name: :assignment_id, in: :path, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns empty review list when no reviews assigned' do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment_id']).to eq(assignment.id)
          expect(data['num_reviews_total']).to eq(0)
          expect(data['num_reviews_completed']).to eq(0)
          expect(data['num_reviews_in_progress']).to eq(0)
          expect(data['reviews']).to eq([])
        end
      end

      response '200', 'returns review list with status for assigned reviews' do
        let(:assignment_id) { assignment.id }

        let!(:mapping) do
          ReviewResponseMap.create!(
            reviewer_id: participant.id,
            reviewee_id: reviewee_team.id,
            reviewed_object_id: assignment.id
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['num_reviews_total']).to eq(1)
          expect(data['reviews'].size).to eq(1)
          review = data['reviews'].first
          expect(review['mapping_id']).to eq(mapping.id)
          expect(review['reviewee_team_id']).to eq(reviewee_team.id)
          expect(review['status']).to eq('not_started')
        end
      end

      response '200', 'marks review as completed when last response is submitted' do
        let(:assignment_id) { assignment.id }

        let!(:mapping) do
          ReviewResponseMap.create!(
            reviewer_id: participant.id,
            reviewee_id: reviewee_team.id,
            reviewed_object_id: assignment.id
          )
        end

        let!(:submitted_response) do
          Response.create!(
            map_id: mapping.id,
            is_submitted: true,
            round: 1
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['num_reviews_completed']).to eq(1)
          expect(data['num_reviews_in_progress']).to eq(0)
          review = data['reviews'].first
          expect(review['status']).to eq('completed')
        end
      end

      response '200', 'marks review as in_progress when response started but not submitted' do
        let(:assignment_id) { assignment.id }

        let!(:mapping) do
          ReviewResponseMap.create!(
            reviewer_id: participant.id,
            reviewee_id: reviewee_team.id,
            reviewed_object_id: assignment.id
          )
        end

        let!(:draft_response) do
          Response.create!(
            map_id: mapping.id,
            is_submitted: false,
            round: 1
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['num_reviews_in_progress']).to eq(1)
          review = data['reviews'].first
          expect(review['status']).to eq('in_progress')
        end
      end

      response '403', 'non-participant cannot list reviews' do
        let!(:other_student) do
          User.create!(
            name: 'sr_other',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other Student',
            email: 'sr_other@example.com'
          )
        end
        let(:token)         { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('You are not a participant in this assignment.')
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

  # -------------------------------------------------------------------------
  # GET /assignments/:assignment_id/student_review/:mapping_id/form
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/student_review/{mapping_id}/form' do
    get 'Review form data for a specific mapping' do
      tags 'StudentReview'
      produces 'application/json'
      parameter name: :assignment_id, in: :path,   type: :integer, required: true
      parameter name: :mapping_id,    in: :path,   type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      let!(:questionnaire) do
        ReviewQuestionnaire.create!(
          name: 'Peer Review Rubric',
          instructor_id: instructor.id,
          private: false,
          min_question_score: 0,
          max_question_score: 5
        )
      end

      let!(:criterion_item) do
        Item.create!(
          questionnaire: questionnaire,
          txt: 'Is the problem statement clear?',
          question_type: 'Criterion',
          seq: 0,
          weight: 1,
          break_before: true
        )
      end

      let!(:assignment_questionnaire) do
        AssignmentQuestionnaire.create!(
          assignment_id: assignment.id,
          questionnaire_id: questionnaire.id,
          questionnaire_weight: 1.0,
          used_in_round: nil,
          dropdown: false
        )
      end

      let!(:mapping) do
        ReviewResponseMap.create!(
          reviewer_id: participant.id,
          reviewee_id: reviewee_team.id,
          reviewed_object_id: assignment.id
        )
      end

      response '200', 'returns questionnaire and mapping info when no response exists yet' do
        let(:assignment_id) { assignment.id }
        let(:mapping_id)    { mapping.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment_id']).to eq(assignment.id)
          expect(data['assignment_name']).to eq(assignment.name)
          expect(data['mapping_id']).to eq(mapping.id)
          expect(data['reviewee_team_name']).to eq(reviewee_team.name)
          expect(data['questionnaire']).not_to be_nil
          expect(data['questionnaire']['name']).to eq('Peer Review Rubric')
          expect(data['questionnaire']['items'].size).to eq(1)
          expect(data['response']).to be_nil
        end
      end

      response '200', 'returns existing submitted response with answers' do
        let(:assignment_id) { assignment.id }
        let(:mapping_id)    { mapping.id }

        let!(:existing_response) do
          Response.create!(
            map_id: mapping.id,
            is_submitted: true,
            round: 1,
            additional_comment: 'Solid work overall.'
          )
        end

        let!(:answer) do
          Answer.create!(
            response_id: existing_response.id,
            item_id: criterion_item.id,
            answer: 4,
            comments: 'Well-explained problem statement.'
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['response']).not_to be_nil
          expect(data['response']['is_submitted']).to be true
          expect(data['response']['additional_comment']).to eq('Solid work overall.')
          answers = data['response']['answers']
          expect(answers.size).to eq(1)
          expect(answers.first['item_id']).to eq(criterion_item.id)
          expect(answers.first['answer']).to eq(4)
          expect(answers.first['comments']).to eq('Well-explained problem statement.')
        end
      end

      response '404', 'mapping not found for this assignment' do
        let(:assignment_id) { assignment.id }
        let(:mapping_id)    { 99_999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('No review found with that ID for this assignment.')
        end
      end

      response '403', 'student who is not the reviewer cannot access the form' do
        let!(:other_student) do
          User.create!(
            name: 'sr_form_other',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other Student',
            email: 'sr_form_other@example.com'
          )
        end
        let!(:other_participant) do
          AssignmentParticipant.create!(
            user_id: other_student.id, parent_id: assignment.id, handle: other_student.name
          )
        end
        let(:token)         { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }
        let(:mapping_id)    { mapping.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('You are not the author of this review.')
        end
      end

      response '403', 'non-participant cannot access the form' do
        let!(:outsider) do
          User.create!(
            name: 'sr_outsider',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Outsider',
            email: 'sr_outsider@example.com'
          )
        end
        let(:token)         { JsonWebToken.encode({ id: outsider.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:assignment_id) { assignment.id }
        let(:mapping_id)    { mapping.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('You are not a participant in this assignment.')
        end
      end

      response '401', 'missing token returns Not Authorized' do
        let(:Authorization) { 'Bearer ' }
        let(:assignment_id)   { assignment.id }
        let(:mapping_id)      { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

# E2619: Tests for POST /quiz_response_maps
# A QuizResponseMap is created when a student takes a team's quiz.
# reviewer_id == reviewee_id (both the reviewer's own AssignmentParticipant id).
RSpec.describe 'QuizResponseMaps API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: 'quiz_rm_instructor',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Quiz RM Instructor',
      email: 'quiz_rm_instructor@example.com'
    )
  end

  let!(:student) do
    User.create!(
      name: 'quiz_rm_student',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Quiz RM Student',
      email: 'quiz_rm_student@example.com'
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'Quiz RM Assignment',
      instructor: instructor
    )
  end

  # Quiz questionnaire owned by the reviewee team
  let!(:quiz_questionnaire) do
    Questionnaire.create!(
      name: 'Team Quiz',
      questionnaire_type: 'Quiz',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor_id: instructor.id
    )
  end

  # Team whose quiz_questionnaire_id points at our quiz
  let!(:reviewee_team) do
    team = Team.create!(name: 'Reviewee Team', parent_id: assignment.id, type: 'AssignmentTeam')
    team.update_column(:quiz_questionnaire_id, quiz_questionnaire.id)
    team
  end

  let(:token) { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # ---------------------------------------------------------------------------
  path '/quiz_response_maps' do
    post 'create a quiz response map' do
      tags 'QuizResponseMaps'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id:    { type: :integer },
          reviewer_user_id: { type: :integer },
          reviewee_team_id: { type: :integer }
        },
        required: %w[assignment_id reviewer_user_id]
      }

      # Happy path: returns 201 with quiz_map_id, quiz_questionnaire_id, reviewer_participant_id
      response(201, 'creates quiz response map and returns required IDs') do
        let(:body_params) do
          {
            assignment_id:    assignment.id,
            reviewer_user_id: student.id,
            reviewee_team_id: reviewee_team.id
          }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data).to have_key('quiz_map_id')
          expect(data).to have_key('quiz_questionnaire_id')
          expect(data).to have_key('reviewer_participant_id')
          expect(data['quiz_questionnaire_id']).to eq(quiz_questionnaire.id)

          # reviewer_id == reviewee_id (quiz convention)
          map = QuizResponseMap.find(data['quiz_map_id'])
          expect(map.reviewer_id).to eq(map.reviewee_id)
        end
      end

      # Idempotent: calling again returns 201 and reuses the same map
      response(201, 'is idempotent — reuses existing map on repeat call') do
        before do
          participant = AssignmentParticipant.find_or_create_by!(
            user_id: student.id, parent_id: assignment.id
          ) { |p| p.handle = student.name }
          map = QuizResponseMap.new(
            reviewed_object_id: quiz_questionnaire.id,
            reviewer_id:        participant.id,
            reviewee_id:        participant.id
          )
          map.save(validate: false)
        end

        let(:body_params) do
          {
            assignment_id:    assignment.id,
            reviewer_user_id: student.id,
            reviewee_team_id: reviewee_team.id
          }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['quiz_map_id']).to be_an(Integer)
          expect(QuizResponseMap.where(reviewed_object_id: quiz_questionnaire.id).count).to eq(1)
        end
      end

      # 400 — missing assignment_id
      response(400, 'returns 400 when assignment_id is missing') do
        let(:body_params) do
          { reviewer_user_id: student.id }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to include('assignment_id')
        end
      end

      # 400 — missing reviewer_user_id
      response(400, 'returns 400 when reviewer_user_id is missing') do
        let(:body_params) do
          { assignment_id: assignment.id }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to include('reviewer_user_id')
        end
      end

      # 404 — unknown assignment
      response(404, 'returns 404 when assignment is not found') do
        let(:body_params) do
          {
            assignment_id:    999_999_999,
            reviewer_user_id: student.id
          }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to match(/assignment/i)
        end
      end

      # 422 — team exists but has no quiz questionnaire
      response(422, 'returns 422 when reviewee team has no quiz questionnaire') do
        let!(:team_no_quiz) do
          Team.create!(name: 'No Quiz Team', parent_id: assignment.id, type: 'AssignmentTeam')
        end

        let(:body_params) do
          {
            assignment_id:    assignment.id,
            reviewer_user_id: student.id,
            reviewee_team_id: team_no_quiz.id
          }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to match(/quiz questionnaire/i)
        end
      end
    end
  end
end

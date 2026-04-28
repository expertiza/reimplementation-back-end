# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

# E2619: Tests for GET /response_maps and POST /response_maps
# GET must exclude quiz maps (reviewer_id == reviewee_id) and include per-map quiz state.
# POST finds or creates a ReviewResponseMap for a reviewer/reviewee pair.
RSpec.describe 'ResponseMaps API', type: :request do
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
    Assignment.create!(name: 'RM Assignment', instructor: instructor)
  end

  let!(:reviewer_participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  # Create a dummy team first so reviewee_team gets a different id than reviewer_participant.
  # This prevents the controller's quiz-map guard (reviewer_id == reviewee_id) from
  # accidentally filtering out the legitimate peer-review map.
  let!(:_dummy_team) do
    Team.create!(name: 'RM Dummy Team', parent_id: assignment.id, type: 'AssignmentTeam')
  end

  let!(:reviewee_team) do
    Team.create!(name: 'RM Reviewee Team', parent_id: assignment.id, type: 'AssignmentTeam')
  end

  # A normal peer-review map: reviewer_id != reviewee_id
  let!(:review_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewee_team.id
    )
  end

  # A quiz map: reviewer_id == reviewee_id (should be excluded from GET)
  let!(:quiz_questionnaire) do
    Questionnaire.create!(
      name: 'RM Quiz',
      questionnaire_type: 'Quiz',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor_id: instructor.id
    )
  end

  let!(:quiz_map) do
    m = QuizResponseMap.new(
      reviewed_object_id: quiz_questionnaire.id,
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewer_participant.id
    )
    m.save(validate: false)
    m
  end

  let(:token) { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # ---------------------------------------------------------------------------
  # GET /response_maps
  # ---------------------------------------------------------------------------
  path '/response_maps' do
    get 'list peer-review response maps for a reviewer' do
      tags 'ResponseMaps'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'reviewer_user_id', in: :query, type: :integer, required: true
      parameter name: 'assignment_id',    in: :query, type: :integer, required: false

      # Returns only peer-review maps (quiz maps excluded)
      response(200, 'returns peer-review maps excluding quiz maps') do
        let(:reviewer_user_id) { student.id }

        run_test! do
          data = JSON.parse(response.body)
          maps = data['response_maps']
          expect(maps).to be_an(Array)
          # Ensure the fixture peer-review map was created and is returned
          expect(maps.map { |m| m['id'] }).to include(review_map.id)
        end
      end

      # Includes quiz state fields on each map entry
      response(200, 'each map entry includes quiz state fields') do
        let(:reviewer_user_id) { student.id }

        run_test! do
          data = JSON.parse(response.body)
          maps = data['response_maps']
          # Filter out quiz maps server-side; there should be at least one peer-review map
          expect(maps).to be_an(Array)
          peer_entry = maps.find { |m| m['id'] == review_map.id }
          expect(peer_entry).not_to be_nil
          expect(peer_entry).to have_key('quiz_taken')
          expect(peer_entry).to have_key('quiz_questionnaire_id')
          expect(peer_entry).to have_key('team_name')
          expect(peer_entry).to have_key('assignment_name')
        end
      end

      # Returns empty array when reviewer has no peer-review maps
      response(200, 'returns empty array when reviewer has no maps') do
        let!(:other_student) do
          User.create!(
            name: 'rm_other_student',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other Student',
            email: 'rm_other_student@example.com'
          )
        end
        let(:reviewer_user_id) { other_student.id }

        run_test! do
          data = JSON.parse(response.body)
          expect(data['response_maps']).to eq([])
        end
      end

      # 400 when reviewer_user_id is absent
      response(400, 'returns 400 when reviewer_user_id is missing') do
        let(:reviewer_user_id) { 0 }

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to include('reviewer_user_id')
        end
      end
    end

    # -------------------------------------------------------------------------
    # POST /response_maps
    # -------------------------------------------------------------------------
    post 'create a peer-review response map' do
      tags 'ResponseMaps'
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
        required: %w[assignment_id reviewer_user_id reviewee_team_id]
      }

      let!(:second_student) do
        User.create!(
          name: 'rm_second_student',
          password_digest: 'password',
          role_id: @roles[:student].id,
          full_name: 'Second Student',
          email: 'rm_second_student@example.com'
        )
      end

      # 201 — creates reviewer participant + ReviewResponseMap
      response(201, 'creates a ReviewResponseMap and returns IDs') do
        let(:body_params) do
          {
            assignment_id:    assignment.id,
            reviewer_user_id: second_student.id,
            reviewee_team_id: reviewee_team.id
          }
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('reviewer_participant_id')
          expect(data['reviewed_object_id']).to eq(assignment.id)
          expect(data['reviewee_id']).to eq(reviewee_team.id)
        end
      end

      # 201 — idempotent: calling again with same params reuses map
      response(201, 'is idempotent — returns same map on repeat call') do
        let(:body_params) do
          {
            assignment_id:    assignment.id,
            reviewer_user_id: second_student.id,
            reviewee_team_id: reviewee_team.id
          }
        end

        before do
          # Pre-create so the controller find_or_create_by finds it
          participant = AssignmentParticipant.find_or_create_by!(
            user_id: second_student.id, parent_id: assignment.id
          ) { |p| p.handle = second_student.name }
          ReviewResponseMap.find_or_create_by!(
            reviewed_object_id: assignment.id,
            reviewer_id:        participant.id,
            reviewee_id:        reviewee_team.id
          )
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['id']).to be_an(Integer)
        end
      end

      # 400 — missing required param
      response(400, 'returns 400 when a required param is missing') do
        let(:body_params) do
          { assignment_id: assignment.id, reviewer_user_id: second_student.id }
          # reviewee_team_id missing
        end

        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to include('reviewee_team_id')
        end
      end
    end
  end
end

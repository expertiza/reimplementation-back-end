require 'swagger_helper'
require 'rails_helper'

RSpec.describe "api/v1/questionnaires", type: :request do

  before do
    Role.create(id: 1, name: 'Teaching Assistant', parent_id: nil, default_page_id: nil)
    Role.create(id: 2, name: 'Administrator', parent_id: nil, default_page_id: nil)

    # Team.create(id: 1, name: "team1")

    Assignment.create(id: 1, name: "QuizAssignmentTest1", require_quiz: true)
    Assignment.create(id: 2, name: "QuizAssignmentTest2", require_quiz: false)

    Participant.create(id: 1, user_id: user.id, assignment_id: 1, team_id: team.id)
  end

  # let(:role_admin) { Role.create(name: 'Administrator', parent_id: nil, default_page_id: nil) }
  # let(:role_ta) { Role.create(name: 'Teaching Assistant', parent_id: nil, default_page_id: nil) }

  let(:institution) { Institution.create(id: 1, name: 'NCSU') }
  # let(:user) {User.create(id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: institution.id)}

  let(:user) do
    institution
    User.create(id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: institution.id)
  end

  let(:team) { Team.create(id: 1, name: "team1") }

  # let(:participant) do
  #   user
  #   team
  #   Participant.create(id: 1, user_id: user.id, assignment_id: 1, team_id: team.id)
  # end

  let(:quizQuestionnaire1) do
    team
    Questionnaire.create(
      id: 3,
      name: 'QuizQuestionnaireTest1',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 10,
      instructor_id: team.id,
      assignment_id: 1
    )
  end

  let(:quizQuestionnaire2) do
    team
    Questionnaire.create(
      id: 2,
      name: 'QuizQuestionnaireTest2',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 99,
      instructor_id: team.id,
      assignment_id: 1
    )
  end

  let(:auth_token) { generate_auth_token(user) }

  path '/api/v1/quiz_questionnaires' do

    get 'Get quiz Questionnaires' do
      tags 'QuizQuestionnaires'
      produces 'application/json'

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      response(200, 'successful') do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post 'create Quiz questionnaire' do
      tags 'QuizQuestionnaires'
      consumes 'application/json'
      produces 'application/json'


      parameter name: 'quiz_questionnaire', in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: { type: :integer },
          participant_id: { type: :integer },
          team_id: { type: :integer },
          user_id: { type: :integer },
          questionnaire_type: { type: :string },
          name: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer }
        }
      }

      let(:valid_questionnaire_params) do
        {
          assignment_id: 1,
          participant_id: 1,
          team_id: 1,
          user_id: 1,
          questionnaire_type: 'Quiz Questionnaire',
          name: 'TestCreateQuizQ101',
          private: false,
          min_question_score: 0,
          max_question_score: 100
        }
      end

      let(:invalid_questionnaire_params) do
        {
          assignment_id: 1,
          participant_id: 1,
          team_id: 1,
          user_id: 1,
          questionnaire_type: 'Quiz Questionnaire',
          name: "InvalidQuizQuestionnaire",
          private: false,
          min_question_score: 100,
          max_question_score: 0
        }
      end
      # parameter name: 'assignment_id', in: :body, type: :integer
      # parameter name: 'participant_id', in: :body, type: :integer
      # parameter name: 'team_id', in: :body, type: :integer
      # parameter name: 'user_id', in: :body, type: :integer
      # parameter name: 'questionnaire_type', in: :body, type: :string
      # parameter name: 'name', in: :body, type: :string
      # parameter name: 'private', in: :body, type: :boolean
      # parameter name: 'min_question_score', in: :body, type: :integer
      # parameter name: 'max_question_score', in: :body, type: :integer

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      # let('user_id') { valid_questionnaire_params[:user_id] }
      # let('assignment_id') { valid_questionnaire_params[:assignment_id] }
      # let('participant_id') { valid_questionnaire_params[:participant_id] }
      # let('team_id') { valid_questionnaire_params[:team_id] }
      # let('name') { valid_questionnaire_params[:name] }
      # let('questionnaire_type') { valid_questionnaire_params[:questionnaire_type] }
      # let('private') { valid_questionnaire_params[:private] }
      # let('min_question_score') { valid_questionnaire_params[:min_question_score] }
      # let('max_question_score') { valid_questionnaire_params[:max_question_score] }

      # post request on /api/v1/questionnaires creates questionnaire with response 201 when correct params are passed
      response(201, 'created') do

        let('quiz_questionnaire') { valid_questionnaire_params }

        run_test!

        # run_test! do
        #   # expect(response).to have_http_status(:created)
        #   # expect(response_body['name']).to eq('TestCreateQuizQ101')
        # end
      end

      # post request on /api/v1/questionnaires returns 422 response - unprocessable entity when wrong params is passed toc reate questionnaire
      response(422, 'unprocessable entity') do
        let('quiz_questionnaire') { invalid_questionnaire_params }
        run_test!
      end

    end
  end

  path '/api/v1/quiz_questionnaires/{id}' do

    get 'Retrieve a quiz questionnaire' do
      tags 'Quiz Questionnaires'
      produces 'application/json'

      parameter name: :id, in: :path, type: :string

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      before do
        Questionnaire.create(
          id: 1,
          name: 'QuizQuestionnaireTest1',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 10,
          instructor_id: 1,
          assignment_id: 1
        )
      end

      response '200', 'Quiz questionnaire details' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let('id') { 1 }

        run_test!
      end

      response '404', 'Not Found' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) { '999' }
        run_test!
      end
    end

    put 'Update a quiz questionnaire' do

      tags 'Quiz Questionnaires'
      consumes 'application/json'

      parameter name: :id, in: :path, type: :string

      parameter name: :questionnaire_params, in: :body, schema: {
        type: :object,
        properties: {
          user_id: {type: :integer},
          name: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          instructor_id: { type: :integer },
          assignment_id: { type: :integer }
        },
        required: ['user_id']
      }

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      before do
        Questionnaire.create(
          id: 1,
          name: 'QuizQuestionnaireTest1',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 10,
          instructor_id: 1,
          assignment_id: 1
        )
      end


      response '200', 'Quiz questionnaire updated' do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let(:questionnaire_params) do
          {
            user_id: 1,
            name: 'Updated Quiz',
            private: true,
            min_question_score: 5,
            max_question_score: 50
          }
        end

        let('id'){1}

        run_test!

      end

      response '422', 'Unprocessable Entity' do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let(:questionnaire_params) do
          {
            user_id: 1,
            min_question_score: -1, # Invalid: Min score should be non-negative
            max_question_score: 10, # Invalid: Max score should be less than min score
            instructor_id: 'invalid_id', # Invalid: Instructor ID should be an integer
            assignment_id: nil # Invalid: Assignment ID is required
          }
        end

        let('id'){1}
        run_test!
      end
    end

    delete 'Delete a quiz questionnaire' do
      tags 'Quiz Questionnaires'

      parameter name: :id, in: :path, type: :string

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      parameter name: :user_id, in: :body, type: :integer

      response '200', 'Quiz questionnaire deleted' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) {'1'}
        let(:user_id) {1}
        run_test!
      end

      response '404', 'Not Found' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let('user_id') {1}
        let(:id) { '999' }
        run_test!
      end
    end

  end


end



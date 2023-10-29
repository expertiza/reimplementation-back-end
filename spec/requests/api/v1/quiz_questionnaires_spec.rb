require 'swagger_helper'

RSpec.describe 'api/v1/quiz_questionnaires', type: :request do

  require 'swagger_helper'

  RSpec.describe "Quiz Questionnaires", type: :request do

    path '/api/v1/quiz_questionnaires' do

      let(:role_admin) { Role.create(name: 'Administrator', parent_id: nil, default_page_id: nil).save }
      let(:role_ta) { Role.create(name: 'Teaching Assistant', parent_id: nil, default_page_id: nil).save }

      let(:institution) { Institution.create(name: 'NCSU').save }

      let(:user) do
        institution
        User.create(name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: role_admin.id, institution_id: institution.id).save!
      end

      let(:assignment_with_quiz) { Assignment.create(name: "QuizAssignmentTest1", require_quiz: true).save! }
      let(:assignment_without_quiz) { Assignment.create(name: "QuizAssignmentTest1", require_quiz: true).save! }

      let(:team) {Team.create(name: "team1").save!}

      let(:quizQuestionnaire1) do
        team
        assignment_with_quiz
        Questionnaire.create(
          name: 'QuizQuestionnaireTest1',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 10,
          instructor_id: team.id,
          assignment_id: assignment_with_quiz.id
        ).save!
      end

      let(:quizQuestionnaire2) do
        team
        assignment_with_quiz
        Questionnaire.create(
          name: 'QuizQuestionnaireTest2',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 99,
          instructor_id: team.id,
          assignment_id: assignment_with_quiz.id
        ).save!
      end

      get('list quiz questionnaires') do
        tags 'QuizQuestionnaires'
        produces 'application/json'
        response(200, 'successful') do
          run_test! do
            expect(response.body.size).to eq(2)
          end
        end
      end

    end



  end


  # path '/api/v1/quiz_questionnaires/copy/{id}' do
  #   # You'll want to customize the parameter types...
  #   parameter name: 'id', in: :path, type: :string, description: 'id'
  #
  #   post('copy quiz_questionnaire') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  # end
  #
  # path '/api/v1/quiz_questionnaires' do
  #
  #   get('list quiz_questionnaires') do
  #     response(200, 'successful') do
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  #
  #   post('create quiz_questionnaire') do
  #     response(200, 'successful') do
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  # end
  #
  # path '/api/v1/quiz_questionnaires/{id}' do
  #   # You'll want to customize the parameter types...
  #   parameter name: 'id', in: :path, type: :string, description: 'id'
  #
  #   get('show quiz_questionnaire') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  #
  #   patch('update quiz_questionnaire') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  #
  #   put('update quiz_questionnaire') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  #
  #   delete('delete quiz_questionnaire') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }
  #
  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  # end
end

require 'swagger_helper'

describe 'Grades API' do
  path '/api/v1/grades/{id}/view' do
    get 'View grade details' do
      tags 'Grades'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/view_team' do
    get 'View team details for grade' do
      tags 'Grades'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/view_scores' do
    get 'View scores for grade' do
      tags 'Grades'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/update' do
    put 'Update grade details' do
      tags 'Grades'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :grade_params, in: :body, schema: {
        type: :object,
        properties: {
          total_score: { type: :integer },
          participant: {"grade": { type: :integer } },
        },
        required: %w[attribute1 attribute2]
      }

      response '200', 'Grade updated successfully' do
        let(:id) { 1 }
        let(:grade_params) { { total_score: 90, participant: { grade: 80 } } }
        run_test!
      end

      response '422', 'Invalid request' do
        let(:id) { 1 }
        let(:grade_params) { { participant: { grade: 70 } } } # Missing required attribute
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}' do
    get 'Show grade details' do
      tags 'Grades'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'Successful operation' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/action_allowed' do
    get 'Check if action is allowed for grade' do
      tags 'Grades'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'Action is allowed' do
        let(:id) { 1 }
        run_test!
      end

      response '403', 'Action is not allowed' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/save_grade_and_comment_for_submission' do
    put 'Save grade and comment for submission' do
      tags 'Grades'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :grade, in: :query, type: :integer, required: true, description: 'Grade value'
      parameter name: :comment, in: :query, type: :string, required: true, description: 'Comment for submission'

      response '200', 'Successful operation' do
        let(:id) { 1 }
        let(:grade) { 90 }
        let(:comment) { 'Excellent work!' }
        run_test!
      end
    end
  end

  # path '/api/v1/grades/{id}/redirect_when_disallowed' do
  #   get 'Redirect when disallowed for grade' do
  #     tags 'Grades'
  #     produces 'application/json'
  #     parameter name: :id, in: :path, type: :integer, required: true
  #
  #     response '200', 'Successful operation' do
  #       let(:id) { 1 }
  #       run_test!
  #     end
  #   end
  # end
  #
  # path '/api/v1/grades/{id}/assign_all_penalties' do
  #   post 'Assign all penalties for grade' do
  #     tags 'Grades'
  #     consumes 'application/json'
  #     produces 'application/json'
  #     parameter name: :id, in: :path, type: :integer, required: true
  #     parameter name: :penalties, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         submission: { type: :integer },
  #         review: { type: :integer },
  #         meta_review: { type: :integer }
  #       },
  #       required: %w[submission review meta_review]
  #     }
  #
  #     response '200', 'Successful operation' do
  #       let(:id) { 1 }
  #       let(:penalties) { { submission: 10, review: 5, meta_review: 2 } }
  #       run_test!
  #     end
  #   end
  # end


end





# # require 'swagger_helper'
# # require 'rails_helper'
# # require 'factory_bot_rails'
# #
# # RSpec.describe 'Grades API', type: :request do
# #
# #   describe 'GET #view_team' do
# #     let(:participant) { create(participant, user_id: 1, parent_id: 4) }
# #     let(:assignment) { participant.assignment }
# #     let(:team) { participant.team }
# #     let(:questionnaires) { create_list(:questionnaire, 2, assignment: assignment, instructor: assignment.instructor, min_question_score: 1, max_question_score: 10) }
# #     let(:questions) { create_list(:question, 5, questionnaire: questionnaires.first) }
# #
# #     before do
# #       allow(controller).to receive(:retrieve_questions).and_return(questions)
# #       # allow(controller).to receive(:participant_scores).and_return(pscore)
# #       get :view_team, params: { id: participant.id }
# #     end
# #
# #     it 'returns a successful response' do
# #       expect(response).to have_http_status(:ok)
# #     end
# #
# #     it 'returns JSON with participant, assignment, team, questions, and pscore' do
# #       expect(JSON.parse(response.body)).to eq({
# #                                                 'participant' => participant.as_json,
# #                                                 'assignment' => assignment.as_json,
# #                                                 'team' => team.as_json,
# #                                                 'questions' => questions.as_json
# #                                                 # 'pscore' => pscore
# #                                               })
# #     end
# #   end
# # end
#
# # require 'swagger_helper'
# # require 'rails_helper'
# # require 'factory_bot_rails'
# #
# # RSpec.describe 'Grades API', type: :request do
# #   describe 'GET #view_team' do
# #     let(:participant) { create(:participant, user_id: 1, parent_id: 4) }
# #     let(:assignment) { participant.assignment }
# #     let(:team) { participant.team }
# #     let(:questionnaires) { create_list(:questionnaire, 2, assignment: participant.assignment, instructor: assignment.instructor, min_question_score: 1, max_question_score: 10) }
# #     let(:questions) { create_list(:question, 5, questionnaire: questionnaires.first) }
# #
# #     before do
# #       allow(controller).to receive(:retrieve_questions).and_return(questions)
# #       get :view_team, params: { id: participant.id }
# #     end
# #
# #     it 'returns a successful response' do
# #       expect(response).to have_http_status(:ok)
# #     end
# #
# #     it 'returns JSON with participant, assignment, team, and questions' do
# #       expect(JSON.parse(response.body)).to eq({
# #                                                 'participant' => participant.as_json,
# #                                                 'assignment' => assignment.as_json,
# #                                                 'team' => team.as_json,
# #                                                 'questions' => questions.as_json
# #                                               })
# #     end
# #   end
# # end
#
#
# require 'swagger_helper'
# require 'factory_bot_rails'
# RSpec.describe 'api/v1/grades', type: :request do
#   let(:bearer_token) { "eyJhbGciOiJSUzI1NiJ9.eyJpZCI6MSwibmFtZSI6ImFkbWluIiwiZnVsbF9uYW1lIjoiYWRtaW4gYWRtaW4iLCJyb2xlIjoiU3VwZXIgQWRtaW5pc3RyYXRvciIsImluc3RpdHV0aW9uX2lkIjoxLCJleHAiOjE3MTM4OTUzNTV9.Nof65HFFlxlMy2PdCJim47GJjBdz0TWSdoRR6gaiZAtR2495yaO8j56VOCSdZDBB7VP546f83hNVl3Hrok8dWNWRDEEvpiIh6B33LgCM8LR9GjWOnWli4EnxFTdSodnVFvUEvskWohwHs9r6ho088MQ51tAE4MGDbPiklGmSdy-2R_fkGKNN93HW1xP_KbU012hBGmQyiMbAzmlfu5SVKWObE7C6iTf36kN8dds1pv9eAPx47DLasTCn8F7k4wD3XLgIP3t_kUNpB85W7HiWnrOJNOJzr0w0lds1W1aNOSTECSollaBpx10lpD2jpO8TMUAvBZuj4B23rEubqc3KzQ" }
#
#   let(:review_response) { build(:response) }
#   let(:assignment) { build(:assignment, id: 1, max_team_size: 2, questionnaires: [review_questionnaire], is_penalty_calculated: true) }
#   let(:assignment2) { build(:assignment, id: 2, max_team_size: 2, questionnaires: [review_questionnaire], is_penalty_calculated: true) }
#   let(:assignment3) { build(:assignment, id: 3, max_team_size: 0, questionnaires: [review_questionnaire], is_penalty_calculated: true) }
#   let(:assignment_questionnaire) { build(:assignment_questionnaire, used_in_round: 1, assignment: assignment) }
#   let(:participant) { build(:participant, id: 1, assignment: assignment, user_id: 1) }
#   let(:participant2) { build(:participant, id: 2, assignment: assignment, user_id: 1) }
#   let(:participant3) { build(:participant, id: 3, assignment: assignment, user_id: 1, grade: 98) }
#   let(:participant4) { build(:participant, id: 4, assignment: assignment2, user_id: 1) }
#   let(:participant5) { build(:participant, id: 5, assignment: assignment3, user_id: 1) }
#   let(:review_questionnaire) { build(:questionnaire, id: 1, questions: [question]) }
#   let(:admin) { build(:admin) }
#   let(:instructor) { build(:instructor, id: 6) }
#   let(:question) { build(:question) }
#   let(:team) { build(:assignment_team, id: 1, assignment: assignment, users: [instructor]) }
#   let(:team2) { build(:assignment_team, id: 2, parent_id: 8) }
#   let(:student) { build(:student, id: 2) }
#   let(:review_response_map) { build(:review_response_map, id: 1) }
#   let(:assignment_due_date) { build(:assignment_due_date) }
#   let(:ta) { build(:teaching_assistant, id: 8) }
#   let(:late_policy) { build(:late_policy) }
#
#   path '/api/v1/grades/{id}/view_scores' do
#     get 'Retrieves a participant\'s grade' do
#       tags 'Grades'
#       produces 'application/json'
#       parameter name: :id, :in => :path, :type => :string
#
#       response '200', 'grade found' do
#         schema type: :object,
#                properties: {
#                  participant: { type: :object,
#                                 properties: {
#                                   id: { type: :integer },
#                                   user_id: { type: :integer },
#                                   parent_id: { type: :integer },
#                                   created_at: { type: :string, format: :'date-time' },
#                                   updated_at: { type: :string, format: :'date-time' },
#                                   grade: { type: :number, format: :float },
#                                   comments_to_student: { type: :string },
#                                   private_instructor_comments: { type: :string }
#                                 },
#                  },
#                },
#                required: ['participant']
#
#         let(:participant) { AssignmentParticipant.find_by(user_id: User.first.id, parent_id: Assignment.first.id) }
#         let(:id) { participant.id }
#         let(:headers) { { 'Authorization': "Bearer #{bearer_token}" } }
#         run_test!
#       end
#
#       response '404', 'participant not found' do
#         let(:id) { 'invalid' }
#         let(:headers) { { 'Authorization': "Bearer #{bearer_token}" } }
#         run_test!
#       end
#     end
#   end
# end



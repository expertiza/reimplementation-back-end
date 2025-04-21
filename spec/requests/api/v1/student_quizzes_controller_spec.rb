# require 'swagger_helper'
# require 'json_web_token'

# RSpec.describe 'StudentQuizzesController', type: :request do
#   before(:all) do
#     @roles = create_roles_hierarchy
#   end
  
#   let(:instructor) {
#     User.create(
#       name: "insta",
#       password_digest: "password",
#       role_id: @roles[:instructor].id,
#       full_name: "Instructor A",
#       email: "instructor@example.com",
#       mru_directory_path: "/home/testuser"
#     )
#   }

#   let(:student) {
#     User.create(
#       name: "stud",
#       password_digest: "password",
#       role_id: @roles[:student].id,
#       full_name: "Student Student",
#       email: "student@example.com",
#       mru_directory_path: "/home/testuser"
#     )
#   }

#   # Embed token based authentication for tests
#   let(:token) { JsonWebToken.encode({ id: instructor.id }) }
#   let(:auth_headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

#   before do
#     allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(instructor)
#     allow_any_instance_of(Api::V1::StudentQuizzesController).to receive(:check_instructor_role).and_return(true)
#   end

#   describe '#index' do
#     it "returns a list of quizzes" do
#       # Create a sample quiz first.
#       Questionnaire.create!(name: "Quiz One", instructor_id: instructor.id,
#                               min_question_score: 0, max_question_score: 10)
#       get '/api/v1/student_quizzes', headers: auth_headers
#       expect(response).to have_http_status(:ok)
#       quizzes = JSON.parse(response.body)
#       expect(quizzes).to be_an(Array)
#     end
#   end

#   describe '#create' do
#     it "creates a new quiz" do
#       params = {
#         questionnaire: {
#           name: "New Quiz",
#           instructor_id: instructor.id,
#           min_question_score: 0,
#           max_question_score: 10,
#           questionnaire_type: "Quiz",  
#           private: false,             
#           items_attributes: [
#             {
#               txt: "Question 1",
#               question_type: "MCQ",
#               correct_answer: "A",
#               score_value: 5,
#               break_before: true, 
#                             def questionnaire_params
#                 params.require(:questionnaire).permit(
#                   :name,
#                   :instructor_id,
#                   :min_question_score,
#                   :max_question_score,
#                   :assignment_id,
#                   :questionnaire_type,
#                   :private,
#                   items_attributes: [
#                     :id,
#                     :txt,
#                     :question_type,
#                     :break_before,
#                     :correct_answer,
#                     :score_value,
#                     :skippable,
#                     { quiz_question_choices_attributes: %i[id answer_text correct] }
#                   ]
#                 )
#               end
              
#               def create_items_and_answers(questionnaire, items_attributes)
#                 items_attributes.each do |item_attr|
#                   quiz_choices = item_attr.delete(:quiz_question_choices_attributes)
#                   item = questionnaire.items.create!(item_attr)
#                   quiz_choices&.each do |choice_attr|
#                     item.quiz_question_choices.create!(choice_attr)
#                   end
#                 end
#               end: [
#                 { answer_text: "A", correct: true },
#                 { answer_text: "B", correct: false }
#               ]
#             }
#           ]
#         }
#       }
#       post '/api/v1/student_quizzes', params: params.to_json, headers: auth_headers
#       expect(response).to have_http_status(:created)
#       data = JSON.parse(response.body)
#       expect(data["name"]).to eq("New Quiz")
#     end
#   end

# end
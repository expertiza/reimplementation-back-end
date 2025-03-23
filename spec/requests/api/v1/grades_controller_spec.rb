require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe Api::V1::GradesController, type: :controller do
    before(:all) do
      @roles = create_roles_hierarchy
    end
  
    let!(:ta) do
      User.create!(
        name: "ta",
        password_digest: "password",
        role_id: @roles[:ta].id,
        full_name: "name",
        email: "ta@example.com"
      )
    end

    let!(:s1) do
        User.create(
        name: "studenta",
        password_digest: "password",
        role_id: @roles[:student].id,
        full_name: "student A",
        email: "testuser@example.com"
        )
    end
    let!(:s2) do
        User.create(
        name: "studentb",
        password_digest: "password",
        role_id: @roles[:student].id,
        full_name: "student B",
        email: "testusebr@example.com"
        )
    end

    let!(:prof) do
        User.create!(
          name: "profa",
          password_digest: "password",
          role_id: @roles[:instructor].id,
          full_name: "Prof A",
          email: "testuser@example.com",
          mru_directory_path: "/home/testuser"
        )
    end

    let!(:instructor) do
        User.create!(
        name: "profn",
        password_digest: "password",
        role_id: @roles[:instructor].id,
        full_name: "Prof n",
        email: "testussder@example.com",
        mru_directory_path: "/home/testuser"
        )
    end

    let(:ta_token) { JsonWebToken.encode({id: ta.id}) }
    let(:student_token) { JsonWebToken.encode({id: s1.id}) }
    let(:instructor_token) { JsonWebToken.encode({ id: instructor.id }) }
    

    let!(:assignment) { Assignment.create!(name: 'Test Assignment',instructor_id: prof.id) }
    let!(:team) { Team.create!(id: 1,  assignment_id: assignment.id) }
    let!(:participant) { AssignmentParticipant.create!(user: s1, assignment_id: assignment.id, team: team, handle: 'handle') }
    let!(:questionnaire) { Questionnaire.create!(name: 'Review Questionnaire',max_question_score:100,min_question_score:0,instructor_id:prof.id) }
    let!(:assignment_questionnaire) { AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire) }
    let!(:question) { Question.create!(questionnaire: questionnaire, txt: 'Question 1',  seq: 1, break_before: 1) }
    # let(:review_questionnaire) { build(:questionnaire, id: 1, questions: [question]) }
    let!(:review_questionnaire) do
        questionnaire.update(questions: [question])
        questionnaire
      end

    describe '#action_allowed' do
        context 'when the user is a Teaching Assistant' do
            it 'allows access to view_team to a TA' do
                request.headers['Authorization'] = "Bearer #{ta_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end
        end
        
        context 'when the user is a Student' do
            it 'allows access to view_team if student is viewing their own team' do    
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_viewing_own_team?).and_return(true)
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_or_ta?).and_return(true)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end

            it 'denies access to view_team if student is not viewing their own team' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_viewing_own_team?).and_return(false)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:forbidden)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => false })
            end

            it 'allows access to view_my_scores if student has finished self review and has proper authorizations' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:self_review_finished?).and_return(true)
                allow_any_instance_of(Api::V1::GradesController).to receive(:are_needed_authorizations_present?).and_return(true)
                
                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_my_scores' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end

            it 'denies access to view_my_scores if student has not finished self review or lacks authorizations' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:self_review_finished?).and_return(false)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_my_scores' }

                expect(response).to have_http_status(:forbidden)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => false })
            end
        end
    end

    describe '#instructor_review' do
        let!(:participant) { AssignmentParticipant.create!(user: s1, assignment_id: assignment.id, team: team, handle: 'handle') }
        let!(:participant2) { AssignmentParticipant.create!(user: s2, assignment_id: assignment.id, team: team, handle: 'handle') }

        let(:assignment_team) { Team.create!(assignment_id: assignment.id) }
        let(:reviewer) { participant }
        let(:reviewee) { participant2 }

        let!(:review_response_map) do
            ReviewResponseMap.create!(
            assignment: assignment,
            reviewer: reviewer,
            reviewee: assignment_team
            )
        end

        let!(:response) do
            Response.create!(
            response_map: review_response_map,
            additional_comment: nil,
            is_submitted: false
            )
        end

        context 'when review exists' do
            it 'redirects to response#edit page' do
            # Stubbing methods for find_participant, find_or_create_reviewer, and find_or_create_review_mapping
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_participant).with('1').and_return(participant)
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_or_create_reviewer).with(instructor.id, participant.assignment.id).and_return(participant)
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_or_create_review_mapping).with(participant.team.id, participant.id, participant.assignment.id).and_return(review_response_map)
            allow(review_response_map).to receive(:new_record?).and_return(false)
            allow(Response).to receive(:find_by).with(map_id: review_response_map.map_id).and_return(response)
            allow(controller).to receive(:redirect_to_review)

            request_params = { id: 1 }
            user_session = { user: instructor }

            request.headers['Authorization'] = "Bearer #{instructor_token}"
            request.headers['Content-Type'] = 'application/json'

            get :instructor_review, params: request_params, session: user_session

            expect(controller).to have_received(:redirect_to_review).with(review_response_map)
            end
        end

        context 'when review does not exist' do
            it 'redirects to response#new page' do
            # Stubbing methods for find_participant, find_or_create_reviewer, and find_or_create_review_mapping
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_participant).with('1').and_return(participant2)
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_or_create_reviewer).with(instructor.id, participant2.assignment.id).and_return(participant2)
            allow_any_instance_of(Api::V1::GradesController).to receive(:find_or_create_review_mapping).with(participant2.team.id, participant2.id, participant2.assignment.id).and_return(review_response_map)
            allow(review_response_map).to receive(:new_record?).and_return(true)
            allow(Response).to receive(:find_by).with(map_id: review_response_map.map_id).and_return(response)
            allow(controller).to receive(:redirect_to_review)

            request_params = { id: 1 }
            user_session = { user: instructor }

            request.headers['Authorization'] = "Bearer #{instructor_token}"
            request.headers['Content-Type'] = 'application/json'

            get :instructor_review, params: request_params, session: user_session

            expect(controller).to have_received(:redirect_to_review).with(review_response_map)
            end
        end
    end

    describe '#update_team' do
        context 'when participant is found and update is successful' do
            it 'updates grade and comment for submission and redirects to grades#view_team page' do
            allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(participant)
            allow(participant.team).to receive(:update).with(grade_for_submission: 100, comment_for_submission: 'comment').and_return(true)

            request.headers['Authorization'] = "Bearer #{ta_token}"
            request.headers['Content-Type'] = 'application/json'
          
            request_params = {participant_id: 1,grade_for_submission: 100,comment_for_submission: 'comment' }
            
            post :update_team, params: request_params
            
            expect(response).to have_http_status(:ok)
            expect(JSON.parse(response.body)).to eq({ "message" => "Grade and comment for submission successfully saved." })            end
        end

        context 'when participant is not found' do
            it 'returns a JSON error message with status 404' do
              allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(nil)

              request.headers['Authorization'] = "Bearer #{ta_token}"
              request.headers['Content-Type'] = 'application/json'
              request_params = { participant_id: 1, grade_for_submission: 100, comment_for_submission: 'comment' }
              
              post :update_team, params: request_params
          
              expect(response).to have_http_status(:not_found)
              expect(JSON.parse(response.body)).to eq({ "error" => "Participant not found." })
            end
        end
          
        context 'when update fails' do
            it 'returns a JSON error message with status 422' do
              allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(participant)
              allow(participant.team).to receive(:update).with(grade_for_submission: 100, comment_for_submission: 'comment').and_return(false)
              
              request.headers['Authorization'] = "Bearer #{ta_token}"
              request.headers['Content-Type'] = 'application/json'
              request_params = { participant_id: 1, grade_for_submission: 100, comment_for_submission: 'comment' }
              
              post :update_team, params: request_params

              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({ "error" => "Error saving grade and comment." })
            end
        end
    end

    describe '#update_participant_grade' do
        context 'when participant is not found' do
            it 'returns a 404 response with an error message' do
            allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(nil)
        
            request_params = {
                id: 1,
                participant: { grade: 100 }
            }
        
            request.headers['Authorization'] = "Bearer #{ta_token}"
            request.headers['Content-Type'] = 'application/json'
            
            # Perform the request
            post :update_participant_grade, params: request_params
        
            # Expecting the response to return 404 with error message
            expect(response.status).to eq(404)
            expect(JSON.parse(response.body)['error']).to eq('Participant not found.')
            end
        end

        context 'when grade is updated successfully' do
            it 'returns a success message with a 200 status' do
              allow(participant).to receive(:update).with(grade: 100).and_return(true)
          
              request_params = {
                id: participant.id,
                participant: { grade: 100 },
                total_score: 100.00
              }
          
              request.headers['Authorization'] = "Bearer #{ta_token}"
              request.headers['Content-Type'] = 'application/json'
          
              post :update_participant_grade, params: request_params
          
              new_grade = 100.00
              # Use request_params[:total_score] instead of params[:total_score]
              expect(format('%.2f', request_params[:total_score].to_f)).to eq(format('%.2f', new_grade))
          
              expect(response.status).to eq(200)
              expect(JSON.parse(response.body)['message']).to eq("A score of 100.0% has been saved for studenta.")
            end
        end
          
        context 'when grade update fails' do
            it 'returns an error message with a 422 status' do
              allow(participant).to receive(:update).and_return(false) 
              allow(participant).to receive(:errors).and_return(double(full_messages: ['Grade cannot be blank']))
          
              request_params = {
                id: participant.id,
                participant: { grade: nil }, 
                total_score: nil 
              }
          
              request.headers['Authorization'] = "Bearer #{ta_token}"
              request.headers['Content-Type'] = 'application/json'
          
              post :update_participant_grade, params: request_params

              new_grade = 100.00
              formatted_total_score = request_params[:total_score].nil? ? '0.00' : format('%.2f', request_params[:total_score].to_f)
          
              expect(formatted_total_score).not_to eq(format('%.2f', new_grade))
          
              expect(response.status).to eq(422)
              expect(JSON.parse(response.body)['message']).to eq(nil)
            end
        end
          
    end

    describe '#edit_participant_scores' do
        before do
            allow(controller).to receive(:find_participant).with(participant.id.to_s).and_return(participant)
            allow(controller).to receive(:list_questions).with(assignment).and_return(question)
            allow(Response).to receive(:review_grades).with(participant, question).and_return([95, 90, 85])  # Example scores
        end

        describe 'GET #edit_participant_scores' do
            it 'renders the edit page and sets instance variables' do
                request.headers['Authorization'] = "Bearer #{instructor_token}"
                request.headers['Content-Type'] = 'application/json'

                get :edit_participant_scores, params: { id: participant.id }

                expect(assigns(:participant)).to eq(participant)
                expect(assigns(:assignment)).to eq(assignment)
                expect(assigns(:scores)).to eq([95, 90, 85])
            end
        end
    end
end

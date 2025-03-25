#require 'rails_helper'
require 'swagger_helper'

RSpec.describe Api::V1::ResponsesController, type: :controller do
  let(:role) { Role.create(name: 'Student') }
  let(:instructor_role) { Role.create(name: 'Instructor') }
  let(:instructor) { Instructor.create(name: 'Teach', email: 'teach@example.com', password: 'qwertfgq123', full_name: 'Teach', role_id: instructor_role.id) }
  let(:user1) { User.create(name: 'User One', email: 'user1@example.com', password: 'asdfas123dfasdfasdf', full_name: 'Full_name 1', role: role) }
  let(:user2) { User.create(name: 'User Two', email: 'user2@example.com', password: 'asdfas176dfadfadfa', full_name: 'Full_name 2', role: role) }
  
  let(:assignment) { Assignment.create(name: 'Test Assignment', directory_path: 'test_assignment', instructor: instructor) }
  let(:reviewee) { Participant.create(user: user1, assignment_id: assignment.id) }
  let(:reviewer) { Participant.create(user: user2, assignment_id: assignment.id) }
  let(:response_map) { ResponseMap.create(reviewee: reviewee, reviewer: reviewer, assignment: assignment) }
  let(:questionnaire) { Questionnaire.create(name: 'Test Questionnaire', max_question_score: 5, min_question_score: 0, instructor: instructor) }
  let(:item) { Item.create(txt: 'Test Question 3', questionnaire: questionnaire)}
  let(:review_questions) { [item, Item.create(txt: 'Test Question 1', questionnaire: questionnaire), Item.create(txt: 'Test Question 2', questionnaire: questionnaire)] }
  let(:response_params) do
    {
      map_id: response_map.id,
      review: {
        questionnaire_id: questionnaire.id,
        round: 1,
        comments: 'Great job!'
      },
      responses: {
        '0' => { score: 98, comment: 'LGTM' }
      },
      isSubmit: 'No'
    }
  end
  let(:new_params) do 
    {
      id: 1
    }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_request!).and_return(true)
    allow_any_instance_of(Api::V1::ResponsesController).to receive(:current_user).and_return(user1)
    allow(controller).to receive(:find_map).and_return(response_map)
    allow(controller).to receive(:find_questionnaire).and_return(questionnaire)
    
    allow(controller).to receive(:update_response)
    allow(controller).to receive(:process_items)
    allow(controller).to receive(:notify_instructor_if_needed)
    allow(ResponseMap).to receive(:find).and_return(response_map)
    allow(controller).to receive(:sort_items).and_return([item])
    allow(controller).to receive(:total_cake_score).and_return(10)
    allow(controller).to receive(:init_answers)

  end

  describe '#action_allowed?' do
    let(:action) { Response.create(map_id: response_map.id, additional_comment: 'Test Comment') }
    before do
      allow(controller).to receive(:current_user).and_return(reviewer)
    end

    context 'when the action is not edit, delete, update, or view' do
      it 'returns true if current_user is not nil' do
        allow(controller).to receive(:params).and_return(action: 'new')
        expect(controller.action_allowed?).to be true
      end

      it 'returns false if current_user is nil' do
        allow(controller).to receive(:current_user).and_return(nil)
        allow(controller).to receive(:params).and_return(action: 'new')
        expect(controller.action_allowed?).to be false
      end
    end

    context 'when the action is edit' do
      before do
        allow(controller).to receive(:params).and_return(action: 'edit', id: action.id)
      end

      it 'returns false if the response is submitted' do
        allow(action).to receive(:is_submitted).and_return(true)
        allow(Response).to receive(:find).and_return(action)
        expect(controller.action_allowed?).to be false
      end

      it 'returns true if the current user is the reviewer and the response is not submitted' do
        allow(action).to receive(:is_submitted).and_return(false)
        allow(Response).to receive(:find).and_return(action)
        allow(controller).to receive(:current_user_is_reviewer?).and_return(true)
        expect(controller.action_allowed?).to be true
      end
    end

    context 'when the action is delete or update' do
      before do
        allow(controller).to receive(:params).and_return(action: 'delete', id: action.id)
      end

      it 'returns true if the current user is the reviewer' do
        allow(Response).to receive(:find).and_return(action)
        allow(controller).to receive(:current_user_is_reviewer?).and_return(true)
        expect(controller.action_allowed?).to be true
      end
    end

    context 'when the action is view' do
      before do
        allow(controller).to receive(:params).and_return(action: 'view', id: action.id)
      end

      it 'returns true if the current user is the reviewer and the response is not submitted' do
        allow(Response).to receive(:find).and_return(action)
        allow(controller).to receive(:response_edit_allowed?).and_return(true)
        expect(controller.action_allowed?).to be true
      end
    end
  end

  describe 'GET #new' do
    before do
      allow(controller).to receive(:prepare_response_content).and_return({
        questionnaire: questionnaire,
        response: Response.create(map_id: response_map.id, additional_comment: 'Test Comment')
      })
      allow(controller).to receive(:find_or_create_response).and_return(Response.create(map_id: response_map.id, additional_comment: 'Test Comment'))
    end
    context 'does this need a context to work' do
      it 'assigns the necessary instance variables and renders the response view' do
        puts Rails.application.routes.recognize_path('/api/v1/responses/new', method: :get)
        get :new, params: new_params
        expect(assigns(:map)).to eq(response_map)
        expect(assigns(:questionnaire)).to eq(questionnaire)
        expect(assigns(:total_score)).to eq(10)
      end
    end
  end

  describe 'POST #create' do
    context 'when the response is successfully created' do
      it 'calls the necessary methods and redirects to response save' do
        puts User.count
        puts Questionnaire.count
        puts response_map.id
        puts Response.count
        
        #binding.pry
 
        expect {
          post :create, params: response_params
        }.to change(Response, :count).by(1)
        
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when the response creation fails' do
      before do
        allow_any_instance_of(Response).to receive(:save).and_return(false)
      end

      it 'does not create a new response and renders an error' do
        expect {
          post :create, params: response_params
        }.not_to change(Response, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #delete' do
    let!(:response_to_delete) { Response.create(map_id: response_map.id, additional_comment: 'Test Comment') }

    it 'destroys the requested response and returns status success' do
      expect {
        delete :destroy, params: { id: response_to_delete.id }
      }.to change(Response, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST #save' do
    let(:response_map) { ResponseMap.create(reviewee: reviewee, reviewer: reviewer, assignment: assignment) }

    it 'saves the response and redirects to the redirect action' do
      post :save, params: { id: response_map.id, return: 'some_return_value', msg: 'some_msg', error_msg: 'some_error_msg' }

      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #new_feedback' do
    let(:response_1) { Response.create(map_id: response_map.id, additional_comment: 'Test Comment') }
    let(:new_feedback_params) { { id: response_1.id } }
    before do
      allow(controller).to receive(:prepare_response_content).and_return({
        questionnaire: questionnaire,
        reviewer: reviewer,
        response: response_1
      })
      allow(AssignmentParticipant).to receive(:where).and_return([user2])
    end

    context 'when the response exists' do
      it 'assigns the necessary instance variables and redirects to new feedback' do
        get :new_feedback, params: new_feedback_params

        expect(assigns(:map)).to eq(response_map)
        expect(assigns(:questionnaire)).to eq(questionnaire)
        expect(assigns(:response)).to eq(response_1)
        expect(response).to have_http_status(:found)
      end
    end

    context 'when the response does not exist' do
      before do
        allow(Response).to receive(:find).and_return(nil)
      end

      it 'redirects back to the fallback location' do
        get :new_feedback, params: new_feedback_params

        expect(controller).to redirect_back(fallback_location: root_path)
      end
    end
  end
end
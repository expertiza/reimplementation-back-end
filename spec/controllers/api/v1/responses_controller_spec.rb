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
    allow(controller).to receive(:redirect_to_response_save)
    allow(ResponseMap).to receive(:find).and_return(response_map)
   

    #allow(response).to receive(:sort_items).and_return([item])
    allow(controller).to receive(:total_cake_score).and_return(10)
    allow(controller).to receive(:init_answers)

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
        puts ResponseMap.count
        puts Response.count
        
        #binding.pry
 
        expect {
          post :create, params: response_params
        }.to change(Response, :count).by(1)
        
        expect(response).to redirect_to(controller: 'response', action: 'save', id: response_map.id)
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
end
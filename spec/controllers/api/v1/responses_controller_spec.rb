require 'rails_helper'

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
  #let(:response) { Response.create(map_id: response_map.id, additional_comment: 'Test Comment') }
  
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
    allow(controller).to receive(:find_map).and_return(response_map)
    allow(controller).to receive(:find_questionnaire).and_return(questionnaire)
    allow(controller).to receive(:find_or_create_response).and_return(Response.create(map_id: response_map.id, additional_comment: 'Test Comment'))
    allow(controller).to receive(:update_response)
    allow(controller).to receive(:process_items)
    allow(controller).to receive(:notify_instructor_if_needed)
    allow(controller).to receive(:redirect_to_response_save)
    allow(ResponseMap).to receive(:find).and_return(response_map)
    allow(controller).to receive(:prepare_response_content).and_return({
      questionnaire: questionnaire,
      response: Response.create(map_id: response_map.id, additional_comment: 'Test Comment')
    })

    #allow(response).to receive(:sort_items).and_return([item])
    allow(controller).to receive(:total_cake_score).and_return(10)
    allow(controller).to receive(:init_answers)

  end

  describe 'GET #new' do
    it 'assigns the necessary instance variables and renders the response view' do
      response_map

      get :new
      expect(assigns(:map_id)).to eq(1)
      expect(assigns(:map)).to eq(response_map)
      expect(assigns(:questionnaire)).to eq(questionnaire)
      expect(assigns(response)).to be_a(Response)
      expect(assigns(:total_score)).to eq(10)
    end
  end

  describe 'POST #create' do
    context 'when the response is successfully created' do
      it 'calls the necessary methods and redirects to response save' do

        response_params
        post :create, params: response_params
 
        expect(Response.count).to eq(1)
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
end
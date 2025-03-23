require 'rails_helper'

RSpec.describe Api::V1::ResponsesController, type: :controller do
  let(:reviewee) { Participant.create(user_id: 1, assignment_id: 1) }
  let(:reviewer) { Participant.create(user_id: 2, assignment_id: 1) }
  let(:assignment) { Assignment.create(name: 'Test Assignment', directory_path: 'test_assignment') }
  let(:response_map) { ResponseMap.create(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: assignment.id) }
  let(:questionnaire) { Questionnaire.create(name: 'Test Questionnaire', max_question_score: 5, min_question_score: 0) }
  let(:review_questions) { [Question.create(txt: 'Test Question 1', questionnaire: questionnaire), Question.create(txt: 'Test Question 2', questionnaire: questionnaire)] }
  let(:response_params) do
    {
      map_id: response_map.id,
      review: {
        questionnaire_id: questionnaire.id,
        round: 1,
        comments: 'Great job!'
      },
      isSubmit: 'Yes'
    }
  end

  before do
    allow(controller).to receive(:find_map).and_return(response_map)
    allow(controller).to receive(:find_questionnaire).and_return(questionnaire)
    allow(controller).to receive(:find_or_create_response).and_return(Response.create(map_id: response_map.id, additional_comment: 'Test Comment'))
    allow(controller).to receive(:update_response)
    allow(controller).to receive(:process_questions)
    allow(controller).to receive(:notify_instructor_if_needed)
    allow(controller).to receive(:redirect_to_response_save)
  end

  describe '#find_map' do
    it 'finds the correct response map' do
      # Setup necessary data
      map = ResponseMap.create(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: assignment.id)

      # Set the necessary params
      controller.params[:map_id] = map.id

      # Call the method directly
      result = controller.send(:find_map)

      # Assert the result
      expect(result.id).to eq(map.id)
    end
  end

  describe 'POST #create' do
    context 'when the response is successfully created' do
      it 'calls the necessary methods and redirects to response save' do
        post :create, params: response_params

        expect(controller).to have_received(:find_map)
        expect(controller).to have_received(:find_questionnaire)
        expect(controller).to have_received(:find_or_create_response)
        expect(controller).to have_received(:update_response).with(true)
        expect(controller).to have_received(:process_questions)
        expect(controller).to have_received(:notify_instructor_if_needed)
        expect(controller).to have_received(:redirect_to_response_save)
      end
    end

    context 'when the response creation fails' do
      before do
        allow(controller).to receive(:find_or_create_response).and_return(nil)
      end

      it 'does not call the subsequent methods and renders an error' do
        post :create, params: response_params

        expect(controller).to have_received(:find_map)
        expect(controller).to have_received(:find_questionnaire)
        expect(controller).to have_received(:find_or_create_response)
        expect(controller).not_to have_received(:update_response)
        expect(controller).not_to have_received(:process_questions)
        expect(controller).not_to have_received(:notify_instructor_if_needed)
        expect(controller).not_to have_received(:redirect_to_response_save)
      end
    end
  end
end
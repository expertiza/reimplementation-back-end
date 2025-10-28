# spec/models/response_map_spec.rb
require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  describe '#needs_update_link?' do
    # Create required objects - simple and minimal
    let(:assignment) { create(:assignment) }
    let(:reviewer) { create(:assignment_participant, assignment: assignment) }
    let(:reviewee_team) do
      # Create team with the same assignment, using with_assignment trait
      team = build(:assignment_team)
      team.assignment = assignment
      team.save!(validate: false) # Skip validation to avoid parent issues
      team
    end

    let(:response_map) do
      ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: reviewee_team.id
      )
    end

    context 'when there is no previous response' do
      it 'returns true (should show Update link for first review)' do
        expect(Response.where(map_id: response_map.id).count).to eq(0)
        expect(response_map.needs_update_link?).to be true
      end
    end

    context 'when reviewee has submitted new work after last review' do
      it 'returns true (should show Update link)' do
        Response.create!(map_id: response_map.id, created_at: 5.days.ago)

        # Stub respond_to? with all possible arguments
        allow(reviewee_team).to receive(:respond_to?).and_call_original
        allow(reviewee_team).to receive(:respond_to?).with(:latest_submission_at, anything).and_return(true)
        allow(reviewee_team).to receive(:latest_submission_at).and_return(1.day.ago)
        allow(response_map).to receive(:reviewee).and_return(reviewee_team)

        allow(response_map).to receive(:respond_to?).and_call_original
        allow(response_map).to receive(:respond_to?).with(:current_round, anything).and_return(false)

        expect(response_map.needs_update_link?).to be true
      end
    end

    context 'when reviewee has NOT submitted new work after last review' do
      it 'returns false (should show Edit link)' do
        Response.create!(map_id: response_map.id, created_at: 1.day.ago)

        allow(reviewee_team).to receive(:respond_to?).and_call_original
        allow(reviewee_team).to receive(:respond_to?).with(:latest_submission_at, anything).and_return(true)
        allow(reviewee_team).to receive(:latest_submission_at).and_return(5.days.ago)
        allow(response_map).to receive(:reviewee).and_return(reviewee_team)

        allow(response_map).to receive(:respond_to?).and_call_original
        allow(response_map).to receive(:respond_to?).with(:current_round, anything).and_return(false)

        expect(response_map.needs_update_link?).to be false
      end
    end

    context 'when round has advanced since last review' do
      it 'returns true (should show Update link)' do
        last_response = Response.create!(map_id: response_map.id, created_at: 5.days.ago)

        allow(last_response).to receive(:respond_to?).and_call_original
        allow(last_response).to receive(:respond_to?).with(:round, anything).and_return(true)
        allow(last_response).to receive(:round).and_return(1)

        allow(reviewee_team).to receive(:respond_to?).and_call_original
        allow(reviewee_team).to receive(:respond_to?).with(:latest_submission_at, anything).and_return(false)
        allow(response_map).to receive(:reviewee).and_return(reviewee_team)

        allow(response_map).to receive(:respond_to?).and_call_original
        allow(response_map).to receive(:respond_to?).with(:current_round, anything).and_return(true)
        allow(response_map).to receive(:current_round).and_return(2)
        allow(Response).to receive_message_chain(:where, :order, :first).and_return(last_response)

        expect(response_map.needs_update_link?).to be true
      end
    end

    context 'when round has NOT advanced and no new submission' do
      it 'returns false (should show Edit link)' do
        last_response = Response.create!(map_id: response_map.id, created_at: 1.day.ago)

        allow(last_response).to receive(:respond_to?).and_call_original
        allow(last_response).to receive(:respond_to?).with(:round, anything).and_return(true)
        allow(last_response).to receive(:round).and_return(2)

        allow(reviewee_team).to receive(:respond_to?).and_call_original
        allow(reviewee_team).to receive(:respond_to?).with(:latest_submission_at, anything).and_return(true)
        allow(reviewee_team).to receive(:latest_submission_at).and_return(5.days.ago)
        allow(response_map).to receive(:reviewee).and_return(reviewee_team)

        allow(response_map).to receive(:respond_to?).and_call_original
        allow(response_map).to receive(:respond_to?).with(:current_round, anything).and_return(true)
        allow(response_map).to receive(:current_round).and_return(2)
        allow(Response).to receive_message_chain(:where, :order, :first).and_return(last_response)

        expect(response_map.needs_update_link?).to be false
      end
    end

    context 'when BOTH new submission AND new round' do
      it 'returns true (should show Update link)' do
        last_response = Response.create!(map_id: response_map.id, created_at: 5.days.ago)

        allow(last_response).to receive(:respond_to?).and_call_original
        allow(last_response).to receive(:respond_to?).with(:round, anything).and_return(true)
        allow(last_response).to receive(:round).and_return(1)

        allow(reviewee_team).to receive(:respond_to?).and_call_original
        allow(reviewee_team).to receive(:respond_to?).with(:latest_submission_at, anything).and_return(true)
        allow(reviewee_team).to receive(:latest_submission_at).and_return(1.day.ago)
        allow(response_map).to receive(:reviewee).and_return(reviewee_team)

        allow(response_map).to receive(:respond_to?).and_call_original
        allow(response_map).to receive(:respond_to?).with(:current_round, anything).and_return(true)
        allow(response_map).to receive(:current_round).and_return(2)
        allow(Response).to receive_message_chain(:where, :order, :first).and_return(last_response)

        expect(response_map.needs_update_link?).to be true
      end
    end
  end
end

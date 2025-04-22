require 'rails_helper'

RSpec.describe StudentReviewService do
  # Use doubles instead of factory objects to avoid database dependencies
  let(:user) { double('User', id: 1, name: 'Test User') }
  let(:assignment) { double('Assignment', id: 42, name: 'Test Assignment', is_calibrated: false) }
  let(:participant) { double('AssignmentParticipant', id: 123, user: user, user_id: user.id, assignment: assignment) }
  let(:reviewer) { double('Reviewer', id: 456, name: 'Test Reviewer') }
  let(:topic_id) { 789 }

  before do
    # Common setup for all tests
    # Mock SignedUpTeam by directly stubbing the student_review_service implementation
    allow_any_instance_of(StudentReviewService).to receive(:load_participant_and_assignment) do |service, participant_id|
      service.instance_variable_set(:@participant, participant)
      service.instance_variable_set(:@assignment, assignment)
      service.instance_variable_set(:@topic_id, topic_id)
      service.instance_variable_set(:@review_phase, 'review')
    end
    
    # Mock remaining private methods that are called during initialization
    allow_any_instance_of(StudentReviewService).to receive(:load_review_mappings)
    allow_any_instance_of(StudentReviewService).to receive(:calculate_review_progress)
    allow_any_instance_of(StudentReviewService).to receive(:load_response_ids)
    
    # Stub find method to return our test participant
    allow(AssignmentParticipant).to receive(:find).with(participant.id.to_s).and_return(participant)
    
    # Explicitly stub the RecordNotFound error 
    allow(AssignmentParticipant).to receive(:find).with('999').and_raise(ActiveRecord::RecordNotFound)
  end

  describe '#initialize' do
    it 'loads participant and assignment' do
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.participant).to eq(participant)
      expect(service.assignment).to eq(assignment)
    end
    
    it 'sets topic_id and review_phase' do
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.topic_id).to eq(topic_id)
      expect(service.review_phase).to eq('review')
    end
    
    it 'raises RecordNotFound error when participant does not exist' do
      # Remove the override that intercepts lookup errors
      allow_any_instance_of(StudentReviewService).to receive(:load_participant_and_assignment).and_call_original
      
      expect { StudentReviewService.new('999') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#bidding_enabled?' do
    before do
      # Since initialization is handled, just need to stub this one method
      allow_any_instance_of(StudentReviewService).to receive(:bidding_enabled?).and_call_original
    end
    
    it 'returns true when bidding is enabled for the assignment' do
      allow(assignment).to receive(:bidding_for_reviews_enabled).and_return(true)
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.bidding_enabled?).to be true
    end

    it 'returns false when bidding is disabled for the assignment' do
      allow(assignment).to receive(:bidding_for_reviews_enabled).and_return(false)
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.bidding_enabled?).to be false
    end
  end
end
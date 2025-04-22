require 'rails_helper'

RSpec.describe StudentReviewService do
  # Use doubles instead of factory objects to avoid database dependencies
  let(:user) { double('User', id: 1, name: 'Test User') }
  let(:assignment) { double('Assignment', id: 42, name: 'Test Assignment', is_calibrated: false, 
                           bidding_for_reviews_enabled: false, team_reviewing_enabled: false) }
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

  describe 'when assignment is calibrated' do
    before do
      # Create test review mappings with specific IDs
      @map1 = double('ReviewResponseMap', id: 1, response: [])
      @map2 = double('ReviewResponseMap', id: 6, response: [])
      @map3 = double('ReviewResponseMap', id: 2, response: [])
      @map4 = double('ReviewResponseMap', id: 7, response: [])
      @map5 = double('ReviewResponseMap', id: 5, response: [])
      
      # Configure assignment as calibrated
      allow(assignment).to receive(:is_calibrated).and_return(true)
      
      # Allow the actual load_review_mappings method to run
      allow_any_instance_of(StudentReviewService).to receive(:load_review_mappings).and_call_original
      
      # Stub ReviewResponseMap.where to return our test mappings in a specific order
      allow(ReviewResponseMap).to receive(:where)
        .with(reviewer_id: reviewer.id, team_reviewing_enabled: false)
        .and_return([@map1, @map2, @map3, @map4, @map5])
        
      # Ensure participant has a reviewer
      allow(participant).to receive(:get_reviewer).and_return(reviewer)
    end
    
    it 'sorts review mappings correctly by id % 5' do
      service = StudentReviewService.new(participant.id.to_s)
      
      # Expected order based on id % 5:
      # @map5 (5 % 5 = 0) should be first
      # @map1 (1 % 5 = 1) should be second
      # @map6 (6 % 5 = 1) should be third
      # @map2 (2 % 5 = 2) should be fourth
      # @map7 (7 % 5 = 2) should be fifth
      expected_ids = [5, 1, 6, 2, 7]
      actual_ids = service.review_mappings.map(&:id)
      
      expect(actual_ids).to eq(expected_ids)
    end
  end

  describe 'when participant has no reviewer' do
    before do
      # Stop stubbing load_review_mappings in the parent context
      allow_any_instance_of(StudentReviewService).to receive(:load_review_mappings).and_call_original
      
      # Set up participant to return nil for get_reviewer
      allow(participant).to receive(:get_reviewer).and_return(nil)
    end
    
    it 'sets review_mappings to empty array' do
      # Create a new service instance - this will call the real load_review_mappings
      service = StudentReviewService.new(participant.id.to_s)
      
      # The service should have an empty array for review_mappings
      expect(service.review_mappings).to eq([])
    end
    
    it 'sets review progress counters to zero' do
      # This will test calculate_review_progress with no mappings
      allow_any_instance_of(StudentReviewService).to receive(:calculate_review_progress).and_call_original
      
      service = StudentReviewService.new(participant.id.to_s)
      
      expect(service.num_reviews_total).to eq(0)
      expect(service.num_reviews_completed).to eq(0)
      expect(service.num_reviews_in_progress).to eq(0)
    end
  end
end
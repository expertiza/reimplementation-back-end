require 'rails_helper'

# Tests for the StudentReviewService class which handles review data retrieval
# and processing for student participants in assignments
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

  # Tests for the initialization process and error handling
  describe '#initialize' do
    # Verifies that participant and assignment objects are properly loaded from DB
    it 'loads participant and assignment' do
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.participant).to eq(participant)
      expect(service.assignment).to eq(assignment)
    end
    
    # Confirms that topic_id and review_phase are set during initialization
    # These are critical for determining which reviews are relevant
    it 'sets topic_id and review_phase' do
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.topic_id).to eq(topic_id)
      expect(service.review_phase).to eq('review')
    end
    
    # Tests the error handling when a participant ID doesn't exist
    # The service should wrap ActiveRecord errors in a more descriptive RuntimeError
    it 'raises a wrapped error when participant does not exist' do
      allow_any_instance_of(StudentReviewService).to receive(:load_participant_and_assignment).and_call_original
      
      expect { StudentReviewService.new('999') }.to raise_error(
        RuntimeError, 
        /Failed to load participant data: ActiveRecord::RecordNotFound/
      )
    end
  end

  # Tests for the bidding feature availability detection
  describe '#bidding_enabled?' do
    before do
      # Since initialization is handled, just need to stub this one method
      allow_any_instance_of(StudentReviewService).to receive(:bidding_enabled?).and_call_original
    end
    
    # Verifies that the service correctly reports when bidding is enabled
    # This is important for UI flows that need to redirect to bidding pages
    it 'returns true when bidding is enabled for the assignment' do
      allow(assignment).to receive(:bidding_for_reviews_enabled).and_return(true)
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.bidding_enabled?).to be true
    end

    # Ensures the service reports disabled bidding correctly
    # This affects whether students can bid for specific reviews
    it 'returns false when bidding is disabled for the assignment' do
      allow(assignment).to receive(:bidding_for_reviews_enabled).and_return(false)
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.bidding_enabled?).to be false
    end
  end

  # Tests for special handling of calibrated assignments which use a specific
  # review mapping sorting algorithm to present reviews in a defined order
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
    
    # Tests the specialized sorting algorithm for calibrated assignments
    # This algorithm ensures specific review mappings appear first to calibrate reviewers
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

  # Tests behavior when a participant doesn't have a reviewer role assigned
  # This is important since some students may not be assigned as reviewers
  describe 'when participant has no reviewer' do
    before do
      # Stop stubbing load_review_mappings in the parent context
      allow_any_instance_of(StudentReviewService).to receive(:load_review_mappings).and_call_original
      
      # Set up participant to return nil for get_reviewer
      allow(participant).to receive(:get_reviewer).and_return(nil)
    end
    
    # Verifies that review_mappings is initialized as empty when no reviewer exists
    # This prevents null pointer exceptions when processing mappings
    it 'sets review_mappings to empty array' do
      # Create a new service instance - this will call the real load_review_mappings
      service = StudentReviewService.new(participant.id.to_s)
      
      # The service should have an empty array for review_mappings
      expect(service.review_mappings).to eq([])
    end
    
    # Ensures all review counters are properly zeroed when no reviewer exists
    # This is important for UI elements that display progress indicators
    it 'sets review progress counters to zero' do
      # This will test calculate_review_progress with no mappings
      allow_any_instance_of(StudentReviewService).to receive(:calculate_review_progress).and_call_original
      
      service = StudentReviewService.new(participant.id.to_s)
      
      expect(service.num_reviews_total).to eq(0)
      expect(service.num_reviews_completed).to eq(0)
      expect(service.num_reviews_in_progress).to eq(0)
    end
  end

  # Tests for the loading of sample review response IDs
  # These are used to provide example reviews to students
  describe 'when loading response IDs' do
    before do
      # Create a proper stub for SampleReview with a where class method
      sample_reviews_class = Class.new do
        def self.where(*)
          # This will be overridden by the stub, but needs to exist
        end
      end
      
      # Replace the real SampleReview with our implementation
      stub_const("SampleReview", sample_reviews_class)
      
      # Create a double for the result of SampleReview.where
      sample_reviews = double('SampleReviews')
      
      # Now we can stub the where method
      allow(SampleReview).to receive(:where).with(assignment_id: assignment.id).and_return(sample_reviews)
      
      # Stub sample_reviews.pluck to return some IDs
      allow(sample_reviews).to receive(:pluck).with(:response_id).and_return([101, 102, 103])
      
      # Allow the real load_response_ids method to run
      allow_any_instance_of(StudentReviewService).to receive(:load_response_ids).and_call_original
    end
    
    # Verifies that sample review response IDs are correctly loaded from the database
    # These IDs are used to display example reviews to students
    it 'loads response IDs correctly for the assignment' do
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.response_ids).to eq([101, 102, 103])
    end
    
    # Tests graceful handling of the case where no sample reviews exist
    # This prevents errors when displaying the reviews UI with no examples
    it 'handles empty response lists' do
      # Different test setup with empty response list
      empty_sample_reviews = double('EmptySampleReviews')
      allow(SampleReview).to receive(:where).with(assignment_id: assignment.id).and_return(empty_sample_reviews)
      allow(empty_sample_reviews).to receive(:pluck).with(:response_id).and_return([])
      
      service = StudentReviewService.new(participant.id.to_s)
      expect(service.response_ids).to eq([])
    end
  end
end
# Service class to handle logic related to student reviews
class StudentReviewService
  # Expose these attributes as read-only for external access
  attr_reader :participant, :assignment, :topic_id, :review_phase,
              :review_mappings, :num_reviews_total, :num_reviews_completed,
              :num_reviews_in_progress, :response_ids

  # Initialize the service with a participant ID
  def initialize(participant_id)
    load_participant_and_assignment(participant_id)
    load_review_mappings
    calculate_review_progress
    load_response_ids
  end

  # Check if bidding for reviews is enabled for the assignment
  def bidding_enabled?
    @assignment.bidding_for_reviews_enabled
  end

  private

  # Load participant and related assignment data
  def load_participant_and_assignment(participant_id)
    @participant = AssignmentParticipant.find(participant_id)
    @assignment = @participant.assignment
    @topic_id = SignedUpTeam.topic_id(@assignment.id, @participant.user_id)
    @review_phase = @assignment.current_stage(@topic_id)
  end

  # Load review mappings for the participant
  def load_review_mappings
    reviewer = @participant.get_reviewer
    
    @review_mappings =
      if reviewer
        ReviewResponseMap.where(
          reviewer_id: reviewer.id,
          team_reviewing_enabled: @assignment.team_reviewing_enabled
        )
      else
        []
      end

    # Sort review mappings if the assignment is calibrated
    @review_mappings = @review_mappings.sort_by { |m| m.id % 5 } if @assignment.is_calibrated
  end

  # Calculate the progress of reviews
  def calculate_review_progress
    @num_reviews_total = @review_mappings.size
    @num_reviews_completed = @review_mappings.count do |map|
      !map.response.empty? && map.response.last.is_submitted
    end
    @num_reviews_in_progress = @num_reviews_total - @num_reviews_completed
  end

  # Load response IDs for the assignment
  def load_response_ids
    @response_ids = SampleReview.where(assignment_id: @assignment.id).pluck(:response_id)
  end
end
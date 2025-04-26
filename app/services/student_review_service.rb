# Service class to handle logic related to student reviews
class StudentReviewService
  # Expose these attributes as read-only for external access
  attr_reader :participant, 
              :assignment, 
              :topic_id, 
              :review_phase,
              :review_mappings, 
              :num_reviews_total, 
              :num_reviews_completed,
              :num_reviews_in_progress, 
              :response_ids

  # Initialize the service with a participant ID
  def initialize(participant_id)
    @participant_id = participant_id
    initialize_review_data
  end

  private

  def initialize_review_data
    load_participant_and_assignment
    load_review_mappings
    calculate_review_progress
    load_response_ids
  end

  # Load participant and related assignment data
  def load_participant_and_assignment
    load_participant
    load_assignment
    set_topic_and_phase
  rescue ActiveRecord::RecordNotFound => e
    handle_not_found_error(e)
  end
  # The participant is the core entity for which reviews are being managed.
  def load_participant
    @participant = AssignmentParticipant.find(@participant_id)
  end

  def load_assignment
    @assignment = @participant.assignment
  end
  # The topic ID identifies the specific topic the participant is working on, and the review phase determines the current stage of the review process
  def set_topic_and_phase
    @topic_id = fetch_topic_id
    @review_phase = fetch_review_phase
  end

  def fetch_topic_id
    SignedUpTeam.topic_id(@assignment.id, @participant.user_id)
  end

  def fetch_review_phase
    @assignment.current_stage(@topic_id)
  end

  # Review mappings link the participant to the reviews they are responsible for.
  # This method ensures that all relevant mappings are fetched and sorted if the assignment is calibrated.
  def load_review_mappings
    reviewer = @participant.get_reviewer
    @review_mappings = fetch_review_mappings(reviewer)
    sort_mappings_if_calibrated
  end
    # It ensures that only mappings relevant to the participant's assignment are fetched.
  def fetch_review_mappings(reviewer)
    return [] unless reviewer

    ReviewResponseMap.where(
      reviewer_id: reviewer.id,
      team_reviewing_enabled: @assignment.team_reviewing_enabled
    )
  end
  # Sorts review mappings if the assignment is calibrated
  # Calibrated assignments require specific ordering of review mappings to prioritize certain reviews.
  def sort_mappings_if_calibrated
    @review_mappings = @review_mappings.sort_by { |m| m.id % 5 } if @assignment.is_calibrated
  end

  # Calculate the progress of reviews
  def calculate_review_progress
    @num_reviews_total = calculate_total_reviews
    @num_reviews_completed = calculate_completed_reviews
    @num_reviews_in_progress = calculate_in_progress_reviews
  end

  def calculate_total_reviews
    @review_mappings.size
  end

  def calculate_completed_reviews
    @review_mappings.count { |map| review_completed?(map) }
  end
  # Checks if a review is completed
  # This method ensures that the review has responses and the last response is submitted.
  def review_completed?(map)
    !map.response.empty? && map.response.last.is_submitted
  end

  def calculate_in_progress_reviews
    @num_reviews_total - @num_reviews_completed
  end

  # Load response IDs for the assignment
  def load_response_ids
    @response_ids = fetch_response_ids
  end

  def fetch_response_ids
    SampleReview.where(assignment_id: @assignment.id).pluck(:response_id)
  end

  def handle_not_found_error(error)
    raise "Failed to load participant data: #{error.message}"
  end
end
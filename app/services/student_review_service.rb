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

  # Determines if bidding for reviews is enabled for this assignment
  # Used to decide whether to redirect users to bidding interface
  def bidding_enabled?
    @assignment&.bidding_for_reviews_enabled
  end

  # Returns true if the participant has a reviewer role assigned
  # Used to determine if review functionality should be displayed
  def has_reviewer?
    @participant.get_reviewer.present?
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

  # Fetches participant record from database using the participant ID
  def load_participant
    @participant = AssignmentParticipant.find(@participant_id)
  end

  # Gets the assignment associated with the participant
  def load_assignment
    @assignment = @participant.assignment
  end

  # Sets topic ID and review phase based on participant and assignment
  def set_topic_and_phase
    @topic_id = fetch_topic_id
    @review_phase = fetch_review_phase
  end

  # Retrieves the topic ID for this participant in the assignment
  # Returns nil if the participant is not signed up for any topic
  def fetch_topic_id
    SignedUpTeam.topic_id(@assignment.id, @participant.user_id)
  end

  # Gets the current review phase/stage for this assignment and topic
  def fetch_review_phase
    @assignment.current_stage(@topic_id)
  end

  # Load review mappings for the participant
  def load_review_mappings
    reviewer = @participant.get_reviewer
    @review_mappings = fetch_review_mappings(reviewer)
    sort_mappings_if_calibrated
  end

  # Retrieves review mappings for the given reviewer
  # Returns an empty array if no reviewer exists
  def fetch_review_mappings(reviewer)
    return [] unless reviewer

    ReviewResponseMap.where(
      reviewer_id: reviewer.id,
      team_reviewing_enabled: @assignment.team_reviewing_enabled
    )
  end

  # Sorts review mappings with a special algorithm for calibrated assignments
  # This ensures certain calibration reviews appear first to improve review consistency
  def sort_mappings_if_calibrated
    @review_mappings = @review_mappings.sort_by { |m| m.id % 5 } if @assignment.is_calibrated
  end

  # Calculate the progress of reviews
  def calculate_review_progress
    @num_reviews_total = calculate_total_reviews
    @num_reviews_completed = calculate_completed_reviews
    @num_reviews_in_progress = calculate_in_progress_reviews
  end

  # Counts the total number of review mappings
  def calculate_total_reviews
    @review_mappings.size
  end

  # Counts how many reviews have been completed (submitted)
  def calculate_completed_reviews
    @review_mappings.count { |map| review_completed?(map) }
  end

  # Determines if a review is completed based on response submission status
  # A review is complete if it has at least one response that is submitted
  def review_completed?(map)
    !map.response.empty? && map.response.last.is_submitted
  end

  # Calculates reviews that are assigned but not yet completed
  def calculate_in_progress_reviews
    @num_reviews_total - @num_reviews_completed
  end

  # Load response IDs for the assignment
  def load_response_ids
    @response_ids = fetch_response_ids
  end

  # Fetches sample review response IDs for this assignment
  # These are used to display example reviews to students
  def fetch_response_ids
    SampleReview.where(assignment_id: @assignment.id).pluck(:response_id)
  end

  # Handles RecordNotFound errors with a more descriptive error message
  def handle_not_found_error(error)
    raise "Failed to load participant data: #{error.message}"
  end
end
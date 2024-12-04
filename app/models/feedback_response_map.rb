class FeedbackResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy

  # Shortcut for getting the assignment of the review (through the review map)
  def assignment
    review.map.assignment
  end

  # Returns reivew display if it exists, or a default message otherwise
  def show_review
    if review
      review.display_as_html
    else
      'No review was performed'
    end
  end

  # Returns the string 'Feedback', as this is a feedback response map
  def title
    'Feedback'
  end

  # Returns the questionnaire associated with the feedback
  def questionnaire
    assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire')
  end

  # Shortcut for getting the reviewee of the feedback (through the review map)
  def contributor
    review.map.reviewee
  end

  def self.feedback_response_report(id, _type)
    # Example query
    # SELECT distinct reviewer_id FROM response_maps where type = 'FeedbackResponseMap' and
    # reviewed_object_id in (select id from responses where
    # map_id in (select id from response_maps where reviewed_object_id = 722 and type = 'ReviewResponseMap'))
    @review_response_map_ids = ReviewResponseMap.where(['reviewed_object_id = ?', id]).pluck('id')

    # Call the helper method to get the authors of the feedback
    @authors = get_feedback_authors(id)

    @temp_review_responses = Response.where(['map_id IN (?)', @review_response_map_ids])
    # we need to pick the latest version of review for each round
    # @temp_response_map_ids = [] # moving this to helper methods!
    if Assignment.find(id).varying_rubrics_by_round?
      # Call the helper method to get the response ids for the varying rubrics
      @all_review_response_ids_rounds = varying_rubrics_report(@temp_review_responses)
      # Return the authors and the varying rubric response ids
      to_return = [@authors]
      # Get the keys and sort them (we can safely assume that the keys are integers)
      review_response_keys = @all_review_response_ids_rounds.keys.sort
      # Add the response ids to the return array in order
      review_response_keys.each do |key|
        to_return << @all_review_response_ids_rounds[key]
      end
      to_return
    else
      # Call the helper method to get the response ids for the static rubrics
      @all_review_response_ids = static_rubrics_report(@temp_review_responses)
      [@authors, @all_review_response_ids]
    end
  end

  # rubocop:disable Metrics/AbcSize
  # Send emails for author feedback
  # Refactored from email method in response.rb
  def email(defn, _participant, assignment)
    defn[:body][:type] = 'Author Feedback'
    # reviewee is a response, reviewer is a participant
    # we need to track back to find the original reviewer on whose work the author comments
    response_id_for_original_feedback = reviewed_object_id
    response_for_original_feedback = Response.find response_id_for_original_feedback
    response_map_for_original_feedback = ResponseMap.find response_for_original_feedback.map_id
    original_reviewer_participant_id = response_map_for_original_feedback.reviewer_id

    participant = AssignmentParticipant.find(original_reviewer_participant_id)

    defn[:body][:obj_name] = assignment.name

    user = User.find(participant.user_id)

    defn[:to] = user.email
    defn[:body][:first_name] = user.fullname
    Mailer.sync_message(defn).deliver
  end
  # rubocop:enable Metrics/AbcSize

  ### PRIVATE METHODS FOR USE IN SIMPLIFYING self.feedback_response_report
  # Used in the first section of self.feedback_response_report to get the authors of the feedback
  private_class_method def self.get_feedback_authors(id)
    # Get the teams for the assignment
    teams = AssignmentTeam.includes([:users]).where(parent_id: id)
    # Initialize the authors array
    @authors = []
    # For each team, get the users and add them to the authors array
    teams.each do |team|
      team.users.each do |user|
        participant = AssignmentParticipant.where(parent_id: id, user_id: user.id).first
        @authors << participant
      end
    end
    @authors
  end

  # Used in the conditional of self.feedback_response_report to get the rubric reports if the rounds vary
  private_class_method def self.varying_rubrics_report(review_responses)
    # Create an array of response map ids
    response_map_ids = []
    # Initialize the array of response map ids
    # This will be a dictionary, where the key is the round number and the value is an array of response ids
    # If the dictionary does not have a key for a round, that key will be initialized with an empty array
    all_review_response_ids_rounds = []
    # For each response, add the response id to the appropriate round array
    review_responses.each do |response|
      # Skip (next) if the response is already in the array
      next if response_map_ids.include? response.map_id.to_s + response.round.to_s

      # Otherwise, add the response map to the tracker array and the response id to the appropriate round array
      response_map_ids << response.map_id.to_s + response.round.to_s
      # If the round is not already in the dictionary, initialize it with an empty array
      all_review_response_ids_rounds[response.round] ||= [] # Creates a new entry only if it does not already exist
      all_review_response_ids_rounds[response.round] << response.id
    end
    all_review_response_ids_rounds
  end

  # Used in the conditional of self.feedback_response_report to get the rubric reports if the rounds do not vary
  private_class_method def self.static_rubrics_report(review_responses)
    # create an array of response_map_ids
    response_map_ids = []
    # Initialize the array of response map ids
    all_review_response_ids = []
    # For each response, add the response id to the array
    review_responses.each do |response|
      # Skip if the response is already in the array
      next if response_map_ids.include? response.map_id

      # Otherwise, add the response map to the tracker array and the response id to the return array
      response_map_ids << response.map_id
      all_review_response_ids << response.id
    end
    all_review_response_ids
  end
end

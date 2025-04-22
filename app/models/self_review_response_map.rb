class SelfReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id'

  # Find a review questionnaire associated with this self-review response map's assignment
  def questionnaire(round_number = nil, topic_id = nil)
    Questionnaire.find(assignment.review_questionnaire_id(round_number, topic_id))
  end

  # This method helps to find contributor - here Team ID
  def contributor
    Team.find_by(id: reviewee.team_id)
  end

  # This method returns 'Title' of type of review (used to manipulate headings accordingly)
  def get_title
    'Self Review'
  end

  # do not send any reminder for self review received.
  def email(defn, participant, assignment); end

  # Creates a self review mapping if one doesn't already exist
  # @param assignment_id [Integer] The ID of the assignment
  # @param reviewer_id [Integer] The ID of the reviewer (participant)
  # @param reviewer_userid [Integer] The user ID of the reviewer
  # @return [OpenStruct] An object containing:
  #   - success [Boolean] Whether the self-review was created successfully
  #   - self_review_map [SelfReviewResponseMap] The created mapping if successful
  #   - error [String] Error message if any
  def self.create_self_review(assignment_id:, reviewer_id:, reviewer_userid:)
    Rails.logger.debug "Creating self-review with assignment_id: #{assignment_id}, reviewer_id: #{reviewer_id}, reviewer_userid: #{reviewer_userid}"
    
    # Find the assignment
    assignment = Assignment.find_by(id: assignment_id)
    unless assignment
      Rails.logger.error "Assignment not found with ID: #{assignment_id}"
      return OpenStruct.new(success: false, error: 'Assignment not found')
    end
    Rails.logger.debug "Found assignment: #{assignment.inspect}"

    # Find the reviewer participant
    reviewer = Participant.find_by(id: reviewer_id, user_id: reviewer_userid, assignment_id: assignment_id)
    unless reviewer
      Rails.logger.error "Reviewer participant not found with ID: #{reviewer_id}, user_id: #{reviewer_userid}, assignment_id: #{assignment_id}"
      return OpenStruct.new(success: false, error: 'Reviewer participant not found')
    end
    Rails.logger.debug "Found reviewer: #{reviewer.inspect}"

    # Find the team through the participant
    team = reviewer.team
    unless team
      Rails.logger.error "No team found for reviewer: #{reviewer.inspect}"
      return OpenStruct.new(success: false, error: 'No team found for this participant')
    end
    Rails.logger.debug "Found team: #{team.inspect}"

    # Find all participants in the team
    team_participants = Participant.where(team_id: team.id, assignment_id: assignment_id)
    if team_participants.empty?
      Rails.logger.error "No participants found in team: #{team.inspect}"
      return OpenStruct.new(success: false, error: 'No participants found in team')
    end
    Rails.logger.debug "Found team participants: #{team_participants.inspect}"

    # Use the first team participant as the reviewee
    reviewee = team_participants.first
    Rails.logger.debug "Using reviewee: #{reviewee.inspect}"

    # Check if self-review already exists
    if exists?(reviewee_id: reviewee.id, reviewer_id: reviewer_id)
      Rails.logger.error "Self review already exists for reviewee: #{reviewee.id}, reviewer: #{reviewer_id}"
      return OpenStruct.new(success: false, error: 'Self review already assigned')
    end

    # Create the self-review mapping
    begin
      Rails.logger.debug "Creating self-review mapping with: reviewee_id: #{reviewee.id}, reviewer_id: #{reviewer_id}, reviewed_object_id: #{assignment_id}"
      
      # Try using a different approach to create the record
      self_review_map = new(
        reviewee_id: reviewee.id,
        reviewer_id: reviewer_id,
        reviewed_object_id: assignment_id,
        type: 'SelfReviewResponseMap'
      )
      
      if self_review_map.save
        Rails.logger.debug "Created self-review mapping: #{self_review_map.inspect}"
        OpenStruct.new(success: true, self_review_map: self_review_map)
      else
        Rails.logger.error "Failed to save self-review mapping: #{self_review_map.errors.full_messages.join(', ')}"
        OpenStruct.new(success: false, error: "Validation error: #{self_review_map.errors.full_messages.join(', ')}")
      end
    rescue => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      OpenStruct.new(success: false, error: "Unexpected error: #{e.message}")
    end
  end
end 
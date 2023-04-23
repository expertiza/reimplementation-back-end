class FeedbackResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy

  # class variables
  @review_response_map_ids # stores the ids of the response map
  @temp_response_map_ids = [] # stores the ids before the rounds are classified
  @all_review_response_ids_round_one = [] # Feedback response from round 1
  @all_review_response_ids_round_two = [] # Feedback response from round 2
  @all_review_response_ids_round_three = [] # Feedback response from round 3
  @all_review_response_ids = [] # stores the ids of the reviewers response

  # get the assignment instance associated with the the instance of this feedback_response_map
  # this instance is associated with a review instance hence the lookup is chained
  def assignment
    review.map.assignment
  end

  # get review html for the associated review instance
  def show_review
    if review
      review.display_as_html
    else
      'No review was performed'
    end
  end

  # getter for title. All response map types have a unique title
  def title
    'Feedback'
  end


  # get the questionaries associated with this instance of the feedback response map
  # the response map belongs to an assignment hence this is a convenience function for getting the questionaires
  def questionnaires
    assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire')
  end

  # get the reviewee of this map instance
  def contributor
    review.map.reviewee
  end

  # finds the responses for round one, two, and three along with response ids
  # @param id is the review object id
  def self.latest_feedback(id)
    @temp_review_responses = Response.where(['map_id IN (?)', @review_response_map_ids]).order('created_at DESC')
    # we need to pick the latest version of review for each round

    if Assignment.find(id).vary_by_round?

      @temp_review_responses.each do |response|
        next if @temp_response_map_ids.include? response.map_id.to_s + response.round.to_s

        @temp_response_map_ids << response.map_id.to_s + response.round.to_s
        @all_review_response_ids_round_one << response.id if response.round == 1
        @all_review_response_ids_round_two << response.id if response.round == 2
        @all_review_response_ids_round_three << response.id if response.round == 3
      end
    else

      @temp_review_responses.each do |response|
        unless @temp_response_map_ids.include? response.map_id
          @temp_response_map_ids << response.map_id
          @all_review_response_ids << response.id
        end
      end
    end
  end

  # get a feedback response report a given review object. This provides ability to see all feedback response for a review
  # @param id is the review object id
  def self.feedback_response_report(id)
    @review_response_map_ids = ReviewResponseMap.where(['reviewed_object_id = ?', id]).pluck('id')
    teams = AssignmentTeam.includes([:users]).where(parent_id: id)
    @authors = []
    teams.each do |team|
      team.users.each do |user|
        participant = AssignmentParticipant.where(parent_id: id, user_id: user.id).first
        @authors << participant
      end
    end

    # Finds the reviews from round one, two and three
    self.latest_feedback(id)

    # @feedback_response_map_ids = ResponseMap.where(["reviewed_object_id IN (?) and type = ?", @all_review_response_ids, type]).pluck("id")
    # @feedback_responses = Response.where(["map_id IN (?)", @feedback_response_map_ids]).pluck("id")
    if Assignment.find(id).vary_by_round?
      return @authors, @all_review_response_ids_round_one, @all_review_response_ids_round_two, @all_review_response_ids_round_three
    else
      return @authors, @all_review_response_ids
    end
  end

  # Send emails for author feedback
  # @param email_command is a command object which will be fully hydrated in this function an dpassed to the mailer service
  # email_command should be initialized to a nested hash which invoking this function {body: {}}
  # @param assignment is the assignment instance for which the email is related to
  def send_email(email_command, assignment)
    email_command[:body][:type] = 'Author Feedback'
    response_id_for_original_feedback = reviewed_object_id
    response_for_original_feedback = Response.find response_id_for_original_feedback
    response_map_for_original_feedback = ResponseMap.find response_for_original_feedback.map_id
    original_reviewer_participant_id = response_map_for_original_feedback.reviewer_id

    participant = AssignmentParticipant.find(original_reviewer_participant_id)

    email_command[:body][:obj_name] = assignment.name

    user = User.find(participant.user_id)

    email_command[:to] = user.email
    email_command[:body][:first_name] = user.fullname
    ApplicationMailer.sync_message(email_command).deliver
  end
end

class FeedbackResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  has_many :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
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
  def  assignment
    review.map.assignment
  end

  # getter for title. All response map types have a unique title
  def title
    'Feedback'
  end


  # get the questionaries associated with this instance of the feedback response map
  # the response map belongs to an assignment hence this is a convenience function for getting the questionaires
  def author_feedback_questionnaire
    assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire')
  end

  # get the reviewee of this map instance
  def contributor
    review.map.reviewee
  end

  # get a feedback response report a given review object. This provides ability to see all feedback response for a review
  # @param id is the review object id
  def self.feedback_response_report_by_round(id)
    # Get the review response map IDs for the specified assignment
    review_response_map_ids = ReviewResponseMap.where(['reviewed_object_id = ?', id]).pluck('id')

    # Get the teams for the specified assignment
    teams = AssignmentTeam.includes([:users]).where(parent_id: id)

    # If the assignment varies by round, filter the responses by round
    if Assignment.find(id).vary_by_round?
      # Get the responses for the specified round
      responses = Response.where(['map_id IN (?)', review_response_map_ids]).order('created_at DESC').where('round IN (?)', [1, 2, 3])
    else
      # Get the last response for the assignment
      responses = Response.where(['map_id IN (?)', review_response_map_ids]).order('created_at DESC').last
    end

    # Create an iterator object
    iterator = FeedbackResponseReportIterator.new(teams, responses)

    # Yield the authors and review responses to the block
    iterator.each do |author, response|
      yield author, response
    end
  end

  # Send emails for author feedback
  # @param email_command is a command object which will be fully hydrated in this function an dpassed to the mailer service
  # email_command should be initialized to a nested hash which invoking this function {body: {}}
  # @param assignment is the assignment instance for which the email is related to
  def send_email(email_command, assignment)
    mail = AuthorFeedbackEmailSendingMethod.new(email_command, assignment, reviewed_object_id)
    mail.accept(AuthorFeedbackEmailVisitor.new)
  end
end

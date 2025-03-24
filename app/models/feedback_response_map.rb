class FeedbackResponseMap < ResponseMap
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'

  # Returns the title used for display
  def title
    'Feedback'
  end

  # Gets the feedback questionnaire associated with the assignment
  def questionnaire
    review_response_map.assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire')
  end

  # Returns the original contributor (the author who received the review)
  def contributor
    review_response_map.reviewee
  end

  # Returns the team being reviewed in the original review
  def team
    review_response_map.reviewee_team
  end

  # Returns the reviewer who gave the original review
  def reviewer
    review_response_map.reviewer
  end

end
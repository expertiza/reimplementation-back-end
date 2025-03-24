class FeedbackResponseMap < ResponseMap
  # old implementation improvements and corrections
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy
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

  # Returns the round number of the original review (if applicable)
  def round
    review_response_map&.response&.round
  end

  # Returns a report of feedback responses, grouped dynamically by round
  def self.feedback_response_report(assignment_id, _type)
    authors = fetch_authors_for_assignment(assignment_id)
    review_map_ids = ReviewResponseMap.where(reviewed_object_id: assignment_id).pluck(:id)
    review_responses = Response.where(map_id: review_map_ids).order(created_at: :desc)

    if Assignment.find(assignment_id).varying_rubrics_by_round?
      latest_by_map_and_round = {}

      review_responses.each do |response|
        key = [response.map_id, response.round]
        latest_by_map_and_round[key] ||= response
      end

      grouped_by_round = latest_by_map_and_round.values.group_by(&:round)
      sorted_by_round = grouped_by_round.sort.to_h # {round_number => [response1_id, response2_id, ...]}
      response_ids_by_round = sorted_by_round.transform_values { |resps| resps.map(&:id) }

      [authors] + response_ids_by_round.values
    else
      latest_by_map = {}

      review_responses.each do |response|
        latest_by_map[response.map_id] ||= response
      end

      [authors, latest_by_map.values.map(&:id)]
    end
  end

  # Fetches all participants who authored submissions for the assignment
  def self.fetch_authors_for_assignment(assignment_id)
    Assignment.find(assignment_id).teams.includes(:users).flat_map do |team|
      team.users.map do |user|
        AssignmentParticipant.find_by(parent_id: assignment_id, user_id: user.id)
      end
    end.compact
  end
end
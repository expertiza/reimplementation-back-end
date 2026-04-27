# frozen_string_literal: true
class FeedbackResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy

  def assignment 
    review.map.assignment
  end 

  def questionnaire 
    Questionnaire.find_by(id: reviewed_object_id)
  end 

  def get_title 
    FEEDBACK_RESPONSE_MAP_TITLE
  end

  def questionnaire_type
    'AuthorFeedback'
  end

  # Returns authors (AssignmentParticipant) for the assignment and the IDs of the
  # latest-per-map review responses that received author feedback.
  # When the assignment uses varying rubrics by round, returns round-bucketed response ID arrays.
  def self.feedback_response_report(assignment_id)
    review_map_ids = ReviewResponseMap.where(reviewed_object_id: assignment_id).pluck(:id)

    teams = AssignmentTeam.includes(:users).where(parent_id: assignment_id)
    authors = teams.flat_map do |team|
      team.users.filter_map do |user|
        AssignmentParticipant.find_by(parent_id: assignment_id, user_id: user.id)
      end
    end

    # Collect latest review responses per map (ordered newest-first)
    temp_responses = Response.where(map_id: review_map_ids).order(created_at: :desc)

    assignment = Assignment.find(assignment_id)
    seen_map_round_keys = []

    if assignment.varying_rubrics_by_round?
      round_one_ids   = []
      round_two_ids   = []
      round_three_ids = []

      temp_responses.each do |response|
        key = "#{response.map_id}-#{response.round}"
        next if seen_map_round_keys.include?(key)

        seen_map_round_keys << key
        round_one_ids   << response.id if response.round == 1
        round_two_ids   << response.id if response.round == 2
        round_three_ids << response.id if response.round == 3
      end

      [authors, round_one_ids, round_two_ids, round_three_ids]
    else
      all_review_response_ids = []

      temp_responses.each do |response|
        next if seen_map_round_keys.include?(response.map_id)

        seen_map_round_keys << response.map_id
        all_review_response_ids << response.id
      end

      [authors, all_review_response_ids]
    end
  end
end
# frozen_string_literal: true
class FeedbackResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'

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

  # Returns the original contributor (the author who received the review)
  def contributor
    self.reviewee
  end

  # Returns the reviewer who gave the original review
  def reviewer
    self.reviewer
  end

  # Returns the round number of the original review (if applicable)
  def round
    self&.response&.round
  end

  # Returns a report of feedback responses, grouped dynamically by round
  def self.feedback_response_report(assignment_id, _type)
    authors = fetch_authors_for_assignment(assignment_id)
    review_map_ids = review_map_ids = ReviewResponseMap.where(["reviewed_object_id = ?", assignment_id]).pluck("id")
    review_responses = Response.where(["map_id IN (?)", review_map_ids])
    review_responses = review_responses.order("created_at DESC") if review_responses.respond_to?(:order)

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

  def send_feedback_email(assignment)
    FeedbackEmailMailer.new(self, assignment).call
  end

  # Return feedback maps for an assignment
  def self.for_assignment(assignment_id)
    joins(:assignment).where(assignments: { id: assignment_id })
  end

  # Return feedback maps for a reviewer and eager-load responses
  def self.for_reviewer_with_responses(reviewer_id)
    where(reviewer_id: reviewer_id).includes(:responses)
  end

  # Compute response statistics for an assignment
  def self.response_rate_for_assignment(assignment_id)
    total_maps = for_assignment(assignment_id).count

    completed_maps = for_assignment(assignment_id)
                     .joins(:responses)
                     .where(responses: { is_submitted: true })
                     .distinct
                     .count

    {
      total_feedback_maps: total_maps,
      completed_feedback_maps: completed_maps,
      response_rate: total_maps > 0 ? (completed_maps.to_f / total_maps * 100).round(2) : 0
    }
  end

  # Build a new instance from controller params (keeps creation details centralized)
  def self.build_from_params(params)
    new(params)
  end
end

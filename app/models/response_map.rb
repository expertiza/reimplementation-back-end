class ResponseMap < ApplicationRecord
  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  # Returns the title used for display - should be overridden by subclasses
  def title
    self.class.name.sub("ResponseMap", "")
  end

  # Gets the questionnaire associated with the assignment
  def questionnaire
    self.assignment.questionnaires
  end

  # Returns the original contributor
  def contributor
    self.reviewee
  end

  # Returns the round number of the latest response
  def round
    self.responses.order(created_at: :desc).first&.round
  end

  # Returns the latest response
  def latest_response
    self.responses.order(created_at: :desc).first
  end

  # Returns if this response map has any submitted responses
  def has_submitted_response?
    self.responses.where(is_submitted: true).exists?
  end

  # Generate a report for responses grouped by rounds
  def self.response_report(assignment_id, type = nil)
    responses = Response.joins(:response_map)
                       .where(response_maps: { reviewed_object_id: assignment_id })
                       .order(created_at: :desc)

    if Assignment.find(assignment_id).varying_rubrics_by_round?
      group_responses_by_round(responses)
    else
      group_latest_responses(responses)
    end
  end

  private

  def self.group_responses_by_round(responses)
    responses.group_by(&:round)
            .transform_values { |resps| resps.map(&:id) }
  end

  def self.group_latest_responses(responses)
    responses.group_by { |r| r.map_id }
            .transform_values { |resps| resps.first.id }
            .values
  end
end
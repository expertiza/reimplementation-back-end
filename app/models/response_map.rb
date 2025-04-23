# Base class for all types of response maps in the system
# Maps represent relationships between reviewers and reviewees
# Subclasses include ReviewResponseMap, FeedbackResponseMap, etc.
class ResponseMap < ApplicationRecord
  # Core associations that define the reviewer-reviewee relationship
  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  # Convenience alias for id
  alias map_id id

  # Returns the title used for display - should be overridden by subclasses
  # Default implementation removes "ResponseMap" from the class name
  # @return [String] the display title for this type of response map
  def title
    self.class.name.sub("ResponseMap", "")
  end

  # Gets the questionnaire associated with the assignment
  # @return [Array<Questionnaire>] questionnaires linked to this assignment
  def questionnaire
    self.assignment.questionnaires
  end

  # Returns the original contributor (typically the reviewee)
  # Can be overridden by subclasses for different contributor types
  # @return [Participant] the participant being reviewed
  def contributor
    self.reviewee
  end

  # Returns the round number of the latest response
  # Used for tracking multiple rounds of review
  # @return [Integer, nil] the round number or nil if no responses
  def round
    self.responses.order(created_at: :desc).first&.round
  end

  # Returns the latest response for this map
  # @return [Response, nil] the most recent response or nil if none exist
  def latest_response
    self.responses.order(created_at: :desc).first
  end

  # Checks if this map has any submitted responses
  # @return [Boolean] true if there are any submitted responses
  def has_submitted_response?
    self.responses.where(is_submitted: true).exists?
  end

  # Generate a report for responses grouped by rounds
  # @param assignment_id [Integer] the ID of the assignment to report on
  # @param type [String, nil] optional type filter for the report
  # @return [Hash] the response report data
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

  # Groups responses by their round number
  # @param responses [ActiveRecord::Relation] the responses to group
  # @return [Hash] responses grouped by round number
  def self.group_responses_by_round(responses)
    responses.group_by(&:round)
            .transform_values { |resps| resps.map(&:id) }
  end

  # Groups responses by map_id, keeping only the latest response
  # @param responses [ActiveRecord::Relation] the responses to group
  # @return [Array] array of the latest response IDs
  def self.group_latest_responses(responses)
    responses.group_by { |r| r.map_id }
            .transform_values { |resps| resps.first.id }
            .values
  end
end
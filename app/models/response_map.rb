# frozen_string_literal: true

# The ResponseMap model represents the association between reviewers and reviewees for a specific assignment. 
# In Expertiza, this model allows participants (students) to assess each other’s work, acting as a map or link
# between reviewers (who perform evaluations) and reviewees (who are evaluated). This mapping is key to facilitating 
# peer assessments, as it connects specific reviewers to their assigned reviewees within an assignment. 
# The ResponseMap model provides various methods to retrieve responses based on factors like the team being reviewed, 
# the reviewer, or the assignment.

class ResponseMap < ApplicationRecord
  # Relationships:
  # - A ResponseMap can have multiple responses, forming a one-to-many association with the Response model.
  # - It belongs to a reviewer and reviewee, both represented by the Participant model.
  # - It also belongs to an assignment, where each response map is tied to a specific assignment being reviewed.
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  # Validations: 
  validates :reviewer_id, presence: true
  validates :reviewee_id, presence: true
  validates :reviewed_object_id, presence: true
  validates :reviewee_id, uniqueness: { scope: [:reviewer_id, :reviewed_object_id], message: 'Duplicate response map is not allowed.' }


  # Delegations:
  # Simplifies access to the reviewer's fullname and the assignment's name attributes
  # by allowing us to call `reviewer_fullname` and `assignment_name` on ResponseMap instances.
  delegate :fullname, to: :reviewer, prefix: true, allow_nil: true
  delegate :name, to: :assignment, prefix: true, allow_nil: true

  # Aliases:
  # Defines an alias for `id` as `map_id` for improved readability, especially when dealing with foreign key associations.
  alias map_id id

  # Scopes:
  
  # Scope to find all maps for a specific team by reviewee_id
  scope :for_team, ->(team_id) { where(reviewee_id: team_id) }

  # Scope to find all maps associated with a specific reviewer
  scope :by_reviewer, ->(reviewer_id) { where(reviewer_id: reviewer_id) }

  # Scope to find all maps associated with a specific assignment
  scope :for_assignment, ->(assignment_id) { where(reviewed_object_id: assignment_id) }

  # Scope to get maps that have at least one response
  scope :with_responses, -> { joins(:response).distinct }

  # Scope to retrieve maps with at least one submitted response
  scope :with_submitted_responses, -> { joins(:response).where(responses: { is_submitted: true }).distinct }

  # Class Methods:
  # These methods define various ways to retrieve response collections, each with specific filters
  # to provide flexibility in fetching responses based on the reviewer, team, assignment, etc.
  class << self
    # Retrieves all responses associated with a specific team and sorts them by the reviewer’s fullname.
    def assessments_for(team)
      return [] if team.nil?

      fetch_and_sort_responses(for_team(team.id))
    end

    def latest_responses_for_team_by_reviewer(team, reviewer)
      return [] if team.nil? || reviewer.nil?


      fetch_latest_responses(for_team(team.id).by_reviewer(reviewer.id))
    end

    # Fetches all responses submitted by a specific reviewer
    def responses_by_reviewer(reviewer)
      return [] if reviewer.nil?
      fetch_submitted_responses(by_reviewer(reviewer.id))
    end

    # Retrieves only submitted responses from a collection of maps.
    def fetch_submitted_responses(maps)
      maps.with_submitted_responses
          .includes(:response)
          .flat_map { |map| map.response.select(&:is_submitted) }
    end
    
    private

    # Collects and sorts valid responses for the specified maps by reviewer name.
    def fetch_and_sort_responses(maps)
      responses = collect_valid_responses(maps)
      sort_responses_by_reviewer_name(responses)
    end

    # Collects responses from the provided maps, filtering out maps without responses or those with unsubmitted responses.
    def collect_valid_responses(maps)
      maps.includes(:response, reviewer: :user).map do |map|
        next if map.response.empty?

        process_response_by_type(map)
      end.compact
    end

    # Fetches the latest response for a map based on the response type and submission status.
    # For "ReviewResponseMap" types, only submitted responses are considered valid.
    def process_response_by_type(map)
      latest_response = map.response.last
      return nil if latest_response.nil?

      if map.type == 'ReviewResponseMap'
        latest_response if latest_response.is_submitted
      else
        latest_response
      end
    end

    # Sorts the responses alphabetically by the reviewer's fullname for consistent display.
    def sort_responses_by_reviewer_name(responses)
      responses.sort_by { |response| response.map.reviewer_fullname.to_s }
    end

    # Collects the latest submitted responses for each map in the specified maps.
    def fetch_latest_responses(maps)
      maps.includes(:response)
          .map { |map| map.response.last }
          .compact
          .select(&:is_submitted)
    end
  end

  # Instance Methods:
  # - Instance-level methods for ResponseMap objects
end

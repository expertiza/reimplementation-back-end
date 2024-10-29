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
  #Create class methods (public and private) for the response map class

  # Instance Methods:
  # - Instance-level methods for ResponseMap objects
end

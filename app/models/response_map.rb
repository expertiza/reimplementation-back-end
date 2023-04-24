class ResponseMap < ApplicationRecord
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  # returns all responses by a particular reviewee
  def get_all_reviewee_responses
    map_id = ResponseMap.find_by(assignment: map.assignment, reviewer: map.reviewer, reviewee: map.reviewee)
    Response.where(map_id: map_id).all
  end
end

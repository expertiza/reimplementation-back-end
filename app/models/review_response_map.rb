# frozen_string_literal: true
class ReviewResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :review_response_maps, foreign_key: 'reviewee_id'
  has_many :responses, through: :review_response_maps, foreign_key: 'map_id' 

  # returns the assignment related to the response map
  def response_assignment
    return assignment
  end

  def questionnaire_type
    'Review'
  end

  def get_title
    REVIEW_RESPONSE_MAP_TITLE
  end

  # Get the review response map
  def review_map_type
    'ReviewResponseMap'
  end

  # Computes the average review grade for an assignment team.
  # This method aggregates scores from all ReviewResponseMaps (i.e., all reviewers of the team).
  def aggregate_review_grade 
    obtained_score = 0

    # Total number of reviewers for this team
    total_reviewers = review_mappings.size

    # Loop through each ReviewResponseMap (i.e., each reviewer)
    review_mappings.each do |map|
      # Add the review grade (normalized score between 0 and 1) to the total
      obtained_score += map.review_grade
    end

    # Compute the average score across reviewers and convert it to a percentage
    ((obtained_score / total_reviewers) * 100).round(2)
  end
end

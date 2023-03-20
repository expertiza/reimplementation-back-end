class ResponseMap < ApplicationRecord
  extend Scoring
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  # @return id attribute of this response map
  # getter for the reponse map instances id. it's equivalent to the primary key of the repsonse map
  def map_id
    id
  end


  # @abstract method, override in derived classes if required.
  # @return all versions of the responses associates with this response map
  def all_versions
    []
  end

  def delete
    destroy
  end

  # @abstract function. derived classes can overload
  # get review html for the associated review instance
  def show_review
    nil
  end

  # @abstract function. derived classes can overload with custom implementation
  # @return html/text for the associated review feedback
  def show_feedback
    nil
  end

  # evaluates whether this response_map was metareviewed by metareviewer
  # @param metareviewer AssignmentParticipant instance
  def metareviewed_by?(metareviewer)
    MetareviewResponseMap.where(reviewee_id: reviewer.id, reviewer_id: metareviewer.id, reviewed_object_id: id).count > 0
  end

  # assigns a metareviewer to this review (response)
  # @param metareviewer AssignmentParticipant instance
  def assign_metareviewer(metareviewer)
    MetareviewResponseMap.create(reviewed_object_id: id,
                                 reviewer_id: metareviewer.id, reviewee_id: reviewer.id)
  end

  # @abstract function which can be overloaded by derived class
  def survey?
    false
  end

  # @return instance of AssignmentTeam associated with the review this response map belongs to
  def find_team_member
    if type.to_s == 'MetareviewResponseMap'
      review_mapping = ResponseMap.find_by(id: reviewed_object_id)
      team = AssignmentTeam.find_by(id: review_mapping.reviewee_id)
    else
      team = AssignmentTeam.find(reviewee_id)
    end
    team
  end
end

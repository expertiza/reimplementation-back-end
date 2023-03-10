class ResponseMap < ApplicationRecord
  extend Scoring
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  def map_id
    id
  end


  def self.comparator(m1, m2)
    if m1.version_num && m2.version_num
      m2.version_num <=> m1.version_num
    elsif m1.version_num
      -1
    else
      1
    end
  end

  # Placeholder method, override in derived classes if required.
  def get_all_versions
    []
  end

  def delete(_force = nil)
    destroy
  end

  def show_review
    nil
  end

  def show_feedback(_response)
    nil
  end

  # Evaluates whether this response_map was metareviewed by metareviewer
  # @param[in] metareviewer AssignmentParticipant object
  def metareviewed_by?(metareviewer)
    MetareviewResponseMap.where(reviewee_id: reviewer.id, reviewer_id: metareviewer.id, reviewed_object_id: id).count > 0
  end

  # Assigns a metareviewer to this review (response)
  # @param[in] metareviewer AssignmentParticipant object
  def assign_metareviewer(metareviewer)
    MetareviewResponseMap.create(reviewed_object_id: id,
                                 reviewer_id: metareviewer.id, reviewee_id: reviewer.id)
  end

  def survey?
    false
  end

  def find_team_member
    # ACS Have metareviews done for all teams
    if type.to_s == 'MetareviewResponseMap'
      # review_mapping = ResponseMap.find_by(id: map.reviewed_object_id)
      review_mapping = ResponseMap.find_by(id: reviewed_object_id)
      team = AssignmentTeam.find_by(id: review_mapping.reviewee_id)
    else
      team = AssignmentTeam.find(reviewee_id)
    end
    team
  end
end

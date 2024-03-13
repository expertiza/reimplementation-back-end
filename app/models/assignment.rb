class Assignment < ApplicationRecord
  include MetricHelper
  has_many :invitations
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :questionnaires, through: :assignment_questionnaires
  has_many :questionnaires, through: :assignment_questionnaires
  belongs_to :course
  belongs_to :instructor, class_name: 'User', inverse_of: :assignments
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'parent_id', dependent: :destroy
  has_many :users, through: :participants, inverse_of: :assignment
  has_many :teams, class_name: 'AssignmentTeam', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :assignment
  has_many :sign_up_topics, foreign_key: 'assignment_id', dependent: :destroy, inverse_of: :assignment
  has_many :response_maps, foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment

  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def num_review_rounds
    rounds_of_reviews
  end
end

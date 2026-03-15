# frozen_string_literal: true

class AssignmentParticipant < Participant
  include ReviewAggregator
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :response_maps, foreign_key: 'reviewee_id'
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  belongs_to :duty, optional: true
  belongs_to :user
  validates :handle, presence: true

  # Delegation methods to avoid Law of Demeter violations
  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :id, to: :team, prefix: true, allow_nil: true
  delegate :id, to: :assignment, prefix: true, allow_nil: true
  delegate :path, to: :team, prefix: true, allow_nil: true

  # Fetches the team for specific participant
  def team
    AssignmentTeam.team(self)
  end

  # Fetches Assignment Directory.
  def dir_path
    assignment.try :directory_path
  end

  # Gets the student directory path
  def path
    "#{assignment.path}/#{team.directory_num}"
  end
    
  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    self.save
  end

  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def aggregate_teammate_review_grade(teammate_review_mappings)
    compute_average_review_score(teammate_review_mappings)
  end
end

# frozen_string_literal: true

class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  has_many   :join_team_requests, dependent: :destroy
  
  # REFACTOR: Removed `belongs_to :team`
  # This association is incorrect. A participant belongs to a team
  # *through* the `teams_participants` join table, not directly.
  # The `has_many :participants, through: :teams_participants` on Team
  # and `has_many :teams, through: :teams_participants` on Participant
  # (if added) would be the correct way.
  
  has_many :teams_participants, dependent: :destroy
  has_many :teams, through: :teams_participants
  
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :duty, optional: true

  # Validations
  validates :user_id, presence: true
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { 
    in: %w[AssignmentParticipant CourseParticipant], 
    message: "must be either 'AssignmentParticipant' or 'CourseParticipant'" 
  }

  # Methods
  def fullname
    user.full_name
  end

  # Abstract method for polymorphic use (e.g., in Team#validate_participant_type)
  def parent_context
    raise NotImplementedError, "#{self.class} must implement #parent_context"
  end

  # This method is a good example of the Template Method Pattern.
  # It's defined in the base class and relies on `parent_context`
  # from the subclasses.
  def set_handle
    desired = user.handle.to_s.strip
    # Use polymorphic parent_context
    context_participants = self.class.where(parent_id: parent_context.id)

    self.handle = if desired.blank?
                    user.name
                  elsif context_participants.exists?(handle: desired)
                    user.name
                  else
                    desired
                  end
    save
  end
end

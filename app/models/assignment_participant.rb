# frozen_string_literal: true

class AssignmentParticipant < Participant
  belongs_to :duty, optional: true
  validates :handle, presence: true

  def parent_context
    assignment
  end
end

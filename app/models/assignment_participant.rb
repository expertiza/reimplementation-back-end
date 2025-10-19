# frozen_string_literal: true

class AssignmentParticipant < Participant
  include ReviewAggregator
  belongs_to :user
  validates :handle, presence: true

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

  def aggregate_teammate_review_grade(teammate_review_mappings)
    compute_average_review_score(teammate_review_mappings)
  end
end
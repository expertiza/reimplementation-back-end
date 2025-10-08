# frozen_string_literal: true

class AssignmentParticipant < Participant
  belongs_to :user
  belongs_to :duty, optional: true
  validates :handle, presence: true


  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(parent_id: assignment.id, handle: user.handle, type: 'AssignmentParticipant')
                    user.name
                  else
                    user.handle
                  end
    self.save
  end
end

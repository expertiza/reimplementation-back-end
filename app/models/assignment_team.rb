class AssignmentTeam < Team

  # Add Participants to the current Assignment Team
  def add_participant(assignment_id, user)
    return if AssignmentParticipant.find_by(parent_id: assignment_id, user_id: user.id)

    AssignmentParticipant.create(parent_id: assignment_id, user_id: user.id, permission_granted: user.master_permission_granted)
  end
end

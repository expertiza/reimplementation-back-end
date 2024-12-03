class AssignmentTeam < Team

  # Add Participants to the current Assignment Team
  def add_participant(assignment_id, user)
    return if AssignmentParticipant.find_by(assignment_id: assignment_id, user_id: user.id)

    AssignmentParticipant.create(assignment_id: assignment_id, user_id: user.id)
  end

  def received_any_peer_review?
    ResponseMap.where(reviewee_id: id, reviewed_object_id: assignment_id).any?
  end
end

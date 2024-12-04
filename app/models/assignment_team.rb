class AssignmentTeam < Team
  
  # Get Participants of the team
  def assignment_participants
    users = self.users
    participants = []
    users.each do |user|
      participant = AssignmentParticipant.find_by(user_id: user.id, assignment_id: self.assignment.id)
      participants << participant unless participant.nil?
    end
    participants
  end

  def add_participant(assignment_id, user)
    return if AssignmentParticipant.find_by(assignment_id: assignment_id, user_id: user.id)

    AssignmentParticipant.create(assignment_id: assignment_id, user_id: user.id)
  end

  def received_any_peer_review?
    ResponseMap.where(reviewee_id: id, reviewed_object_id: self.assignment.id).any?
  end

  # Prototyping AssignmenTeam to MentoredTeam
  # TODO :: Assign mentor once MentorManagement is implemented
  def upgrade_to_mentored_team
    # Duplicate AssignmentTeam
    mentored_team = self.dup
    
    # Dynamically hook into add_member logic to invoke MentorManagement if can add member
    mentored_team.define_singleton_method(:add_member) do |user, assignment_id|
      # Call the original implementation with the arguments
      can_add_member = super(user, assignment_id)
      # Mentor Management is not yet implemented, so having to comment this line
      # MentorManagement.assign_mentor(_assignment_id, id) if can_add_member
      can_add_member
    end

    # Return overridden team
    mentored_team
  end

  private

  def dup
    ActiveRecord::Base.transaction do
      # Duplicate the team itself
      duplicated_team = self.dup
      duplicated_team.save!

      # Duplicate associated signed_up_teams
      self.signed_up_teams.each do |signed_up_team|
        duplicated_team.signed_up_teams.create!(signed_up_team.attributes.except("id", "team_id", "created_at", "updated_at"))
      end

      # Duplicate associated teams_users and retain user associations
      self.teams_users.each do |teams_user|
        duplicated_team_user = duplicated_team.teams_users.create!(teams_user.attributes.except("id", "team_id", "created_at", "updated_at"))
        duplicated_team_user.user = teams_user.user # Reassociate the existing user
        duplicated_team_user.save!
      end

      # Duplicate participants
      self.participants.each do |participant|
        duplicated_team.participants.create!(participant.attributes.except("id", "team_id", "created_at", "updated_at"))
      end

      duplicated_team
    end
  rescue => e
    Rails.logger.error("Failed to duplicate team: #{e.message}")
    raise ActiveRecord::Rollback
  end
end

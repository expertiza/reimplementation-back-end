class TeamsAssignment < ApplicationRecord

  # Example: Return teams associated with this course
  def get_teams
    CourseTeam.where(parent_id: id)
  end

  # Example: Return participants associated with these teams
  def get_participants
    CourseParticipant.where(parent_id: id)
  end


  # Example: Return a specific participant by user_id
  def get_participant(user_id)
    CourseParticipant.find_by(parent_id: id, user_id: user_id)
  end

  # Example: Add a participant to a team
  def add_participant(user_name)
    user = User.find_by(name: user_name)
    if user.nil?
      raise 'No user account exists with the name ' + user_name + ". Please create the user first."
    end

    participant = CourseParticipant.find_by(parent_id: id, user_id: user.id)
    if participant
      raise "The user #{user.name} is already a participant."
    else
      CourseParticipant.create(parent_id: id, user_id: user.id, permission_granted: user.master_permission_granted)
    end
  end

  # Example: Copy participants from an assignment to these teams
  def copy_participants(assignment_id)
    participants = AssignmentParticipant.where(parent_id: assignment_id)
    errors = []
    participants.each do |participant|
      user = User.find(participant.user_id)

      begin
        add_participant(user.name)
      rescue StandardError => e
        errors << e.message
      end
    end

    unless errors.empty?
      raise errors.join('<br/>')
    end
  end

  # Example: Check if a user is on a team
  def user_on_team?(user)
    teams = get_teams
    users = []
    teams.each do |team|
      users.concat(team.users)
    end
    users.include?(user)
  end

end


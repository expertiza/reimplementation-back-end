class MentoredTeam < AssignmentTeam
  # Adds a participant to the team and automatically assigns a mentor
  # - Only assigns a mentor if the participant was successfully added
  def add_member(participant)
    can_add_member = super(participant.user)
    if can_add_member
      assign_mentor(parent_id, id)
    end
    can_add_member
  end

  # Imports a list of users from the provided hash and adds them as team members
  # - Only adds users who are found and not already in the team
  # - Automatically assigns mentors to eligible teams
  def import_team_members(row_hash)
    row_hash[:teammembers].each do |teammate|
      if teammate.to_s.strip.empty?
        next
      end
      user = User.find_by(name: teammate.to_s)
      if user.nil?
        raise ImportError, "The user '#{teammate}' was not found. <a href='/users/new'>Create</a> this user?"
      else
        unless TeamsParticipant.joins(:participant).exists?(team_id: id, participants: { user_id: user.id })
          participant = AssignmentParticipant.find_by(user_id: user.id, assignment_id: parent_id)
          add_member(participant) if participant
        end
      end
    end
  end

  # Returns the number of non-mentor participants in the team
  # - Overrides base `size` method to exclude mentors
  def size
    participants.reject(&:can_mentor).size
  end

  private

  # Determines if a mentor should be auto-assigned based on assignment and team conditions
  # - Assigns the mentor if all conditions are met and sends notification emails
  def assign_mentor(assignment_id, team_id)
    assignment = Assignment.find(assignment_id)
    team = Team.find(team_id)

    # return if assignments can't accept mentors
    return unless assignment.auto_assign_mentor

    # return if the assignment or team already have a topic
    return if assignment.topics? || !team.topic_id.nil?

    # return if the team size hasn't reached > 50% of capacity
    return if team.size * 2 <= assignment.max_team_size

    # return if there's already a mentor in place
    return if team.participants.any?(&:can_mentor)

    mentor = select_mentor(assignment_id)

    # Add the mentor using team model class.
    team_member_added = mentor.nil? ? false : team.add_member(mentor)
    return unless team_member_added

    notify_team_of_mentor_assignment(mentor, team)
    notify_mentor_of_assignment(mentor, team)
  end

  # Selects the most eligible mentor based on the fewest number of teams they are already mentoring
  # - Returns the mentor user object or nil if no mentors available
  def select_mentor(assignment_id)
    mentor_user_id, = zip_mentors_with_team_count(assignment_id).first
    User.where(id: mentor_user_id).first
  end

  # Returns a sorted list of [mentor_user_id, team_count] pairs
  # - Helps identify mentors with the lightest current load
  def zip_mentors_with_team_count(assignment_id)
    mentor_ids = mentors_for_assignment(assignment_id).pluck(:user_id)
    return [] if mentor_ids.empty?
    team_counts = {}
    mentor_ids.each { |id| team_counts[id] = 0 }
    #E2351 removed (:team_id) after .count to fix balancing algorithm
    team_counts.update(TeamsParticipant
    .joins(:team)
    .where(teams: { parent_id: assignment_id })
    .where(user_id: mentor_ids)
    .group(:user_id)
    .count)
    team_counts.sort_by { |_, v| v }
  end

  # Retrieves all participants in the assignment who are eligible to act as mentors
  def mentors_for_assignment(assignment_id)
    Participant.where(parent_id: assignment_id, can_mentor: true)
  end

  # Sends an email to all team members to notify them of their newly assigned mentor
  def notify_team_of_mentor_assignment(mentor, team)
    members = team.users
    emails = members.map(&:email)
    members_info = members.map { |mem| "#{mem.fullname} - #{mem.email}" }
    mentor_info = "#{mentor.fullname} (#{mentor.email})"
    message = "#{mentor_info} has been assigned as your mentor for assignment #{Assignment.find(team.parent_id).name} <br>Current members:<br> #{members_info.join('<br>')}"

    Mailer.delayed_message(bcc: emails,
                           subject: '[Expertiza]: New Mentor Assignment',
                           body: message).deliver_now
  end

  # Sends an email to the mentor informing them of their new assignment and team members
  def notify_mentor_of_assignment(mentor, team)
    members_info = team.users.map { |mem| "#{mem.fullname} - #{mem.email}" }.join('<br>')
    assignment_name = Assignment.find(team.parent_id).name
    mentor_message = "You have been assigned as a mentor for the team working on assignment: #{assignment_name}. <br>Current team members:<br> #{members_info}"
  
    Mailer.delayed_message(
        bcc: [mentor.email],
        subject: '[Expertiza]: You have been assigned as a Mentor',
        body: mentor_message
      ).deliver_now

  end
end

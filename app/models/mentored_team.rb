# frozen_string_literal: true

class MentoredTeam < AssignmentTeam

  # Custom validation to ensure the team type is 'MentoredTeam'
  validate :type_must_be_mentored_team

  # adds members to the team who are not mentors
  def add_member(participant)
    # This schema has no mentor association; honor one when exposed, comparing users.
    if respond_to?(:mentor) && participant.is_a?(Participant) && participant.user == mentor
      return { success: false, error: 'The mentor cannot be added as a team member' }
    end

    super(participant)
  end

  # Assigning a user as mentor of the team 
  # Validates if user has the role and permission to be a mentor
  def assign_mentor(user)
    return false unless user.role&.name&.downcase&.include?('mentor')
    self.mentor = user
    save
  end

  # Unassigns mentor from team
  def remove_mentor
    self.mentor = nil
    save
  end

  private

  # Check if the team type is 'MentoredTeam'
  def type_must_be_mentored_team
    errors.add(:type, 'must be MentoredTeam') unless type == 'MentoredTeam'
  end
end 

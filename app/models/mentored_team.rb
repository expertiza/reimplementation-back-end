class MentoredTeam < AssignmentTeam
    # Class created during refactoring of E2351
    # Overridden method to include the MentorManagement workflow
    def add_member(user, _assignment_id = nil)
        raise "The user #{user.name} is already a member of the team #{name}" if user?(user)
        raise "A mentor already exists for team #{name}" if mentor_exists? && user.mentor_role?
        can_add_member = false
        unless full? || user.mentor_role?
          can_add_member = true
          t_user = TeamsUser.create(user_id: user.id, team_id: id)
          parent = TeamNode.find_by(node_object_id: id)
          TeamUserNode.create(parent_id: parent.id, node_object_id: t_user.id)
          add_participant(parent_id, user)
          ExpertizaLogger.info LoggerMessage.new('Model:Team', user.name, "Added member to the team #{id}")
        end
        if can_add_member
            MentorManagement.assign_mentor(_assignment_id, id) if user.mentor_role?
        end
        can_add_member
    end
    #E2479
    private

    def mentor_exists?
        teams_users.where(role: 'mentor').exists?
    end
end

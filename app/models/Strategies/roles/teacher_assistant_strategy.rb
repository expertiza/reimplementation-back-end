# Strategy class for TAs; inherits from RoleStrategy
class TeacherAssistantStrategy < RoleStrategy

  def validate_permissions
    raise NotImplementedError("Not implemented")
  end

  # Returns the permissions associated with the TA role in the
  # form of a dictionary
  # @return dictionary containing permissions
  def get_permissions
    return {
      can_submit: false,
      can_review: true,
      can_take_quiz: false,
      can_mentor: true
    }
  end

end

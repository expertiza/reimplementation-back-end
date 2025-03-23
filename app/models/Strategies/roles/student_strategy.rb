# Strategy class for students; inherits from RoleStrategy
class StudentStrategy < RoleStrategy

  def validate_permissions
    raise NotImplementedError("Not implemented")
  end

  # Returns the permissions associated with the Student role in the
  # form of a dictionary
  # @return dictionary containing permissions
  def get_permissions
    return {
      can_submit: true,
      can_review: false,
      can_take_quiz: false,
      can_mentor: false
    }
  end

end

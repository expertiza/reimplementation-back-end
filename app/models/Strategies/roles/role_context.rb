# A Context class that is able to execute role strategy methods from clients
class RoleContext

  # The RoleStrategy currently being used
  attr_reader :strategy

  # Unimplemented
  def validate_permissions
    raise NotImplementedError
  end

  # Returns the permissions associated with the role of the current strategy,
  # but will return nil if there is no strategy set
  #
  # @return associated permissions for a given role; nil if no strategy
  def get_permissions
    @strategy ? return @strategy.get_permissions : return nil
  end

  # Sets a strategy to the RoleContext for use with other functions
  #
  # @param [RoleStrategy] strategy that is to be set
  def set_strategy(strategy)
    @strategy = strategy
  end

  # Sets a strategy via the role of the participant (param[:authorization]). This
  # strategy can then be used for other functions that are a part of this. The
  # function returns a boolean that signifies the success of the function.
  #
  # @param [String] role is the authorization string provided to identify roles
  # @return true if strategy is successful, else false
  def set_strategy_by_role(role)
    # Get proper strategy given the role provided
    case role
    when 'Student'
      @strategy = StudentStrategy.new
    when 'Reviewer'
      @strategy = ReviewerStrategy.new
    when 'Teaching Assistant'
      @strategy = TeacherAssistantStrategy.new
    when 'Mentor'
      @strategy = MentorStrategy.new
    else
      return false
    end
    # Returns true if the strategy is successsfully set
    return true;
  end

end

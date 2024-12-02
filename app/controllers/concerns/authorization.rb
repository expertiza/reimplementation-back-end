module Authorization
  extend ActiveSupport::Concern
  include JwtToken

  # Authorize all actions
  def authorize
    unless all_actions_allowed?
      render json: { 
        error: "You are not authorized to #{params[:action]} this #{params[:controller]}"
      }, status: :forbidden
    end
  end

  # Check if all actions are allowed
  def all_actions_allowed?
    return true if has_required_role?('Administrator')
    action_allowed?
  end

  # Base action_allowed? - allows everything by default
  # Controllers should override this method to implement their authorization logic
  def action_allowed?
    true
  end

  # Checks if current user has the required role or higher privileges
  # @param required_role [Role, String] The minimum role required (can be Role object or role name)
  # @return [Boolean] true if user has required role or higher privileges
  # @example
  #   has_required_role?('Administrator') # checks if user is an admin or higher
  #   has_required_role?(Role::INSTRUCTOR) # checks if user is an instructor or higher
  def has_required_role?(required_role)
    required_role = Role.find_by_name(required_role) if required_role.is_a?(String)
    current_user&.role&.all_privileges_of?(required_role)
  end

  # Unlike has_required_role? which checks for role hierarchy and privilege levels,
  # this method checks if the user has exactly the specified role
  # @param role_name [String, Role] The exact role to check for
  # @return [Boolean] true if user has exactly this role, false otherwise
  # @example
  #   is_role?('Student') # true only if user is exactly a student
  #   is_role?(Role::INSTRUCTOR) # true only if user is exactly an instructor
  def is_role?(role_name)
    role_name = role_name.name if role_name.is_a?(Role)
    current_user&.role&.name == role_name
  end
end
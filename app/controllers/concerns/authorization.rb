module Authorization
  extend ActiveSupport::Concern
  include JwtToken

  # Authorize all actions
  def authorize
    Rails.logger.info "Authorization Header: #{request.headers['Authorization']}"
    Rails.logger.info "Current User: #{current_user&.inspect}"
    unless all_actions_allowed?
      render json: { 
        error: "You are not authorized to #{params[:action]} this #{params[:controller]}"
      }, status: :forbidden
    end
  end

  # Check if all actions are allowed
  def all_actions_allowed?
    return true if has_privileges_of?('Super Administrator')
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
  #   has_privileges_of?('Administrator') # checks if user is an admin or higher
  #   has_privileges_of?(Role::INSTRUCTOR) # checks if user is an instructor or higher
  def has_privileges_of?(required_role)
    required_role = Role.find_by_name(required_role) if required_role.is_a?(String)
    current_user&.role&.all_privileges_of?(required_role) || false
  end

  # Unlike has_privileges_of? which checks for role hierarchy and privilege levels,
  # this method checks if the user has exactly the specified role
  # @param role_name [String, Role] The exact role to check for
  # @return [Boolean] true if user has exactly this role, false otherwise
  # @example
  #   has_role?('Student') # true only if user is exactly a student
  #   has_role?(Role::INSTRUCTOR) # true only if user is exactly an instructor
  def has_role?(required_role)
    required_role = required_role.name if required_role.is_a?(Role)
    current_user&.role&.name == required_role
  end

  def are_needed_authorizations_present?(id, *authorizations)
    authorization = Participant.find_by(id: id)&.authorization
    authorization.present? && !authorizations.include?(authorization)
  end

  # Check if the currently logged-in user is a participant in an assignment
  def current_user_is_assignment_participant?(assignment_id)
    return false unless session[:user]

    AssignmentParticipant.exists?(parent_id: assignment_id, user_id: session[:user].id)
  end
end


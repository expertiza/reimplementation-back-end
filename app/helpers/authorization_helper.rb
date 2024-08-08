module AuthorizationHelper

  # Determine if the currently logged-in user has the privileges of a TA (or higher)
  def current_user_has_ta_privileges?
    current_user_has_privileges_of?('Teaching Assistant')
  end

  # Determine if the currently logged-in user has the privileges of a Student (or higher)
  def current_user_has_student_privileges?
    current_user_has_privileges_of?('Student')
  end

  private

  # Determine if the currently logged-in user has the privileges of the given role name (or higher privileges)
  # If there is no currently logged-in user return false
  def current_user_has_privileges_of?(role_name)
    current_user_and_role_exist? && session[:user].role.has_all_privileges_of?(Role.find_by(name: role_name))
  end

  # Check whether user is logged-in and user role exists
  def current_user_and_role_exist?
    user_logged_in? && !session[:user].role.nil?
  end

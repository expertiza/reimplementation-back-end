module AuthorizationHelper
  # Notes:
  # We use session directly instead of current_role_name and the like
  # Because helpers do not seem to have access to the methods defined in app/controllers/application_controller.rb

  # PUBLIC METHODS

  # Determine if the currently logged-in user has the privileges of a Super-Admin
  def current_user_has_super_admin_privileges?
    current_user_has_privileges_of?('Super-Administrator')
  end

  # Determine if the currently logged-in user has the privileges of an Admin (or higher)
  def current_user_has_admin_privileges?
    current_user_has_privileges_of?('Administrator')
  end

  # Determine if the currently logged-in user has the privileges of an Instructor (or higher)
  def current_user_has_instructor_privileges?
    current_user_has_privileges_of?('Instructor')
  end

  # Determine if the currently logged-in user has the privileges of a TA (or higher)
  def current_user_has_ta_privileges?
    current_user_has_privileges_of?('Teaching Assistant')
  end

  # Determine if the currently logged-in user has the privileges of a Student (or higher)
  def current_user_has_student_privileges?
    current_user_has_privileges_of?('Student')
  end


  # Determine if the currently logged-in user IS of the given role name
  # If there is no currently logged-in user simply return false
  # parameter role_name should be one of: 'Student', 'Teaching Assistant', 'Instructor', 'Administrator', 'Super-Administrator'
  def current_user_is_a?(role_name)
    current_user_and_role_exist? && session[:user].role.name == role_name
  end

  # Determine if the current user has the passed in id value
  # parameter id can be integer or string
  def current_user_has_id?(id)
    user_logged_in? && session[:user].id.eql?(id.to_i)
  end

  
  
  # Determine if there is a current user
  # The application controller method session[:user]
  # will return a user even if session[:user] has been explicitly cleared out
  # because it is "sticky" in that it uses "@session[:user] ||= session[:user]"
  # So, this method can be used to answer a controller's question
  # "is anyone CURRENTLY logged in"
  def user_logged_in?
    !session[:user].nil?
  end

  

  # PRIVATE METHODS
  private

  # Determine if the currently logged-in user has the privileges of the given role name (or higher privileges)
  # Let the Role model define this logic for the sake of DRY
  # If there is no currently logged-in user simply return false
  def current_user_has_privileges_of?(role_name)
    current_user_and_role_exist? && session[:user].role.has_all_privileges_of?(Role.find_by(name: role_name))
  end


  def current_user_and_role_exist?
    user_logged_in? && !session[:user].role.nil?
  end
end

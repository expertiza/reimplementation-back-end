module AuthorizationHelper

  def current_user_has_student_privileges?
    current_user_has_privileges_of?('Student')
  end


  private

  def current_user_has_privileges_of?(role_name)
    current_user_and_role_exist? && session[:user].role.has_all_privileges_of?(Role.find_by(name: role_name))
  end





end
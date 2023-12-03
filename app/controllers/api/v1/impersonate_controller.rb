# Controller for performing Impersonate Operation in Expertiza
require 'json_web_token'

class Api::V1::ImpersonateController < ApplicationController

  # This function checks if the logged in user is a student or not.
  # If it is a student, do not allow the impersonate mode.
  # If the logged in user has the role or anything other than the student,
  # we allow that user to use the impersonate mode.

  before_action :check_if_input_is_valid

  # def action_allowed?
  #   # Check for TA privileges first since TA's also have student privileges.
  #   if ['Student'].include? current_role_name
  #     !session[:super_user].nil?
  #   else
  #     ['Super-Administrator',
  #      'Administrator',
  #      'Instructor',
  #      'Teaching Assistant'].include? current_role_name
  #   end
  # end

  # This function gives the dropdown where we have all the usernames based on the name we enter.
  # We should ideally be able to search for whichever username we want to impersonate.
  # This function does not seem to work

  # def auto_complete_for_user_name
  #   @users = session[:user].get_available_users(params[:user][:name])
  #   render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
  # end

  # Called whenever we want to enter the impersonate mode in the application.

  # def start
  #   flash[:error] = "This page doesn't take any query string." unless request.GET.empty?
  # end

  # This method is created to return the impersonated session
  # It was created to implement the DRY Principle that was not followed in the overwrite_session method
  # It sets session user as the user that is being impersonated.
  # The session is then returned to the overwrite_session

  # def generate_session(user)
  #   AuthController.clear_user_info(session, nil)
  #   session[:original_user] = @original_user
  #   session[:impersonate] = true
  #   session[:user] = user
  # end

  # Method to overwrite the session details that are corresponding to the user or one being impersonated
  # The first 'if' statement is executed if the logged in user tried to access the impersonate feature from his account.
  # The 'elsif' statement is executed if the user is impersonating someone and then tried to impersonate another person.
  # The 'else' statement has not been executed and we believe it can be removed.

  # def overwrite_session
  #   if params[:impersonate].nil?
  #     user = real_user(params[:user][:name])
  #     session[:super_user] = session[:user] if session[:super_user].nil?
  #     generate_session(user)
  #   elsif !params[:impersonate][:name].empty?
  #     user = real_user(params[:impersonate][:name])
  #     generate_session(user)
  #   else
  #     session[:user] = session[:super_user]
  #     session[:super_user] = nil
  #   end
  # end

  # Checks if special characters are present in the username provided, only alphanumeric should be used
  # warn_for_special_chars is a method in SecurityHelper class.SecurityHelper class has methods to handle this.
  # special_chars method-Initialises string with special characters /\?<>|&$# .
  # contains_special_chars method-converts it to regex and compares with the string
  # warn_for_special_chars takes the output from above method and flashes an error if there are any special characters(/\?<>|&$#) in the string

  def check_if_input_is_valid
    # if params[:user].blank? || warn_for_special_chars(params[:user_name], 'Username')
    #   render json: { success: false, error: 'Please enter valid user name' }, status: :unprocessable_entity
    if params[:impersonate].blank? 
      
      # || warn_for_special_chars(params[:impersonate], 'Username')
      render json: { success: false, error: 'Please enter valid user name' }, status: :unprocessable_entity
    end
  end


  # def warn_for_special_chars(str, field_name)
  #   if contains_special_chars? str
  #     render json: { success: false, error: field_name + " must not contain special characters '" + special_chars + "'." }, status: :unprocessable_entity
  #     return true
  #   end
  #   false
  # end

  # def contains_special_chars?(str)
  #   special = special_chars
  #   regex = /[#{special.gsub(/./) { |char| "\\#{char}" }}]/

  # end
  #   def special_chars
  #     '/\\?<>|&$#'
  #   end

  # Checking if the username provided can be impersonated or not
  # If the user is in anonymized view,then fetch the real user else fetch the user using params
  # can_impersonate method in user.rb checks whether the original user can impersonate the other user in params
  # This method checks whether the user is a superadmin or teaching staff or recursively adds the child users till it reached highest hierarchy which is SuperAdmin
  # If original user can impersonate the user ,then session will be overwrite to get the view of the user who is getting impersonated

  # def check_if_user_impersonateable
  #   if params[:impersonate].nil?
  #     user = real_user(params[:user][:name])
  #     unless @original_user.can_impersonate? user
  #       @message = "You cannot impersonate '#{params[:user][:name]}'."
  #       temp
  #       AuthController.clear_user_info(session, nil)
  #     else
  #       overwrite_session
  #     end
  #   else
  #     unless params[:impersonate][:name].empty?
  #       overwrite_session
  #     end
  #   end
  # end

    def check_if_user_impersonateable?
      user = User.find(params[:impersonate] )
      if user
        return @current_user.can_impersonate? user
      end
      false
      end


  # Impersonate using form on /impersonate/start, based on the username provided
  # This method looks to see if that's possible by calling the check_if_user_impersonateable method
  # checking if user impersonateable, if not throw corresponding error message

  # def impersonate
  #   begin
  #     @original_user = session[:super_user] || session[:user]
  #     if params[:impersonate].nil?
  #       @message = "You cannot impersonate '#{params[:user][:name]}'."
  #       @message = 'User name cannot be empty' if params[:user][:name].empty?
  #       user = real_user(params[:user][:name])
  #       check_if_user_impersonateable if user
  #     elsif !params[:impersonate][:name].empty?
  #       # Impersonate a new account
  #       @message = "You cannot impersonate '#{params[:impersonate][:name]}'."
  #       user = real_user(params[:impersonate][:name])
  #       check_if_user_impersonateable if user
  #       # Revert to original account when currently in the impersonated session
  #     elsif !session[:super_user].nil?
  #       AuthController.clear_user_info(session, nil)
  #       session[:user] = session[:super_user]
  #       user = session[:user]
  #       session[:super_user] = nil
  #     end
  #     # Navigate to user's home location as the default landing page after impersonating or reverting
  #     AuthController.set_current_role(user.role_id, session)
  #     redirect_to action: AuthHelper.get_home_action(session[:user]),
  #                 controller: AuthHelper.get_home_controller(session[:user])
  #   rescue StandardError
  #     flash[:error] = @message
  #     redirect_back fallback_location: root_path
  #   end
  # end



  
    def impersonate
      if check_if_user_impersonateable?
        user = User.find(params[:impersonate])
        if user
          # Assuming JsonWebToken has methods to encode and decode tokens
          # You might need to adjust this based on your JWT library
  
          # Encode user information into a new token
          new_payload = { id: user.id, name: user.name, full_name: user.full_name, role: user.role.name,
                          institution_id: user.institution.id }
          new_token = JsonWebToken.encode(new_payload, 24.hours.from_now)
  
          render json: { success: true, token: new_token, message: "Successfully impersonated #{user.name}" }
        else
          render json: { success: false, error: 'User not found' }, status: :not_found
        end
      else
        render json: { success: false, error: "You don't have permission to impersonate this user" }, status: :forbidden
      end
    end
  

  

  # This method checks if the user is in anonymized view and accordingly returns the user object associated with the parameter

#   def real_user(name)
#     if User.anonymized_view?(session[:ip])
#       user = User.real_user_from_anonymized_name(name)
#     else
#       user = User.find_by(name: name)
#     end
#     return user
#   end
end
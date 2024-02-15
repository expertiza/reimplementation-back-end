# Controller for performing Impersonate Operation in Expertiza
require 'json_web_token'

class Api::V1::ImpersonateController < ApplicationController

  # Rails will execute the method check_if_input_is_valid before every action in the controller.
  before_action :check_if_input_is_valid

  # Checks if special characters are present in the username provided, only alphanumeric should be used
  def check_if_input_is_valid
    if params[:impersonate].blank? || warn_for_special_chars(params[:impersonate], 'Username')
      # render json: { success: false, error: 'Please enter valid user name' }, status: :unprocessable_entity
    end
  end

  # Takes the output from above method and flashes an error if there are any special characters (/\?<>|&$#) in the string
  def warn_for_special_chars(str, field_name)
    puts str
    if contains_special_chars? str
      render json: { success: false, error: field_name + " must not contain special characters '" + special_chars + "'." }, status: :unprocessable_entity
      return true
    end
    false
  end

  # Checks if the given string contains any special characters defined in the 'special_chars' set
  # Returns true if any special character is found, otherwise false.
  def contains_special_chars?(str)
    special = special_chars
    regex = /[#{Regexp.escape(special)}]/
    !str.match(regex).nil?
  end
    # Initialises string with special characters /\?<>|&$#
    def special_chars
      '/\\?<>|&$#'
    end

    # Checks if impersonation is allowed for the current user
    # Returns true if allowed, otherwise false.
    def check_if_user_impersonatable?
      user = User.find_by(name: params[:impersonate] )
      if user
        return @current_user.can_impersonate? user
      end
      false
      end


    # can_impersonate method in user.rb checks whether the original user can impersonate the other user in params


    # Impersonates a user if impersonation is allowed, generating a token with user details
    # Otherwise, returns appropriate error messages.
    def impersonate
      if check_if_user_impersonatable?
        user = User.find_by(name: params[:impersonate])

        if user
          impersonate_payload = { id: user.id, name: user.name, full_name: user.full_name, role: user.role.name,
                          institution_id: user.institution.id, impersonate: true, original_user: @current_user }
          impersonate_token = JsonWebToken.encode(impersonate_payload, 24.hours.from_now)
  
          render json: { success: true, token: impersonate_token, message: "Successfully impersonated #{user.name}" }
        else
          render json: { success: false, error: 'User not found' }, status: :not_found
        end
      else
        render json: { success: false, error: "You don't have permission to impersonate this user" }, status: :forbidden
      end
    end

end
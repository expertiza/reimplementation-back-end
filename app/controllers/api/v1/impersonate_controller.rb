# Controller for performing Impersonate Operation in Expertiza
require 'json_web_token'

class Api::V1::ImpersonateController < ApplicationController


  before_action :check_if_input_is_valid


  # Checks if special characters are present in the username provided, only alphanumeric should be used
  # special_chars method-Initialises string with special characters /\?<>|&$# .
  # contains_special_chars method-converts it to regex and compares with the string
  # warn_for_special_chars takes the output from above method and flashes an error if there are any special characters(/\?<>|&$#) in the string
  def check_if_input_is_valid
    if params[:impersonate].blank? || warn_for_special_chars(params[:impersonate], 'Username')
      # render json: { success: false, error: 'Please enter valid user name' }, status: :unprocessable_entity
    end
  end


  def warn_for_special_chars(str, field_name)
    puts str
    if contains_special_chars? str
      render json: { success: false, error: field_name + " must not contain special characters '" + special_chars + "'." }, status: :unprocessable_entity
      return true
    end
    false
  end

  def contains_special_chars?(str)
    special = special_chars
    regex = /[#{Regexp.escape(special)}]/
    !str.match(regex).nil?
  end
    def special_chars
      '/\\?<>|&$#'
    end

  # Checking if the username provided can be impersonated or not
  # can_impersonate method in user.rb checks whether the original user can impersonate the other user in params
    def check_if_user_impersonatable?
      user = User.find_by(name: params[:impersonate] )
      if user
        return @current_user.can_impersonate? user
      end
      false
      end


  
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
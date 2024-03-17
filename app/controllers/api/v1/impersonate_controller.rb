class Api::V1::ImpersonateController < ApplicationController
  # before_action :check_if_input_is_valid

  def get_users_list
    users = current_user.get_available_users(params[:user_name])
    render json: { message: "Successfully Fetched User List!", userList:users, success:true }, status: :ok
  end

  def impersonate
  #   Logic For Impersonate
  render json: { message: "Successfully Impersonated User!", newjwt:"token" }, status: :ok
  end

end
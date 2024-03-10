class Api::V1::ImpersonateController < ApplicationController
  # before_action :check_if_input_is_valid

  def user_name_list
  #   Logic For Fetching User List
  render json: { message: "Successfully Fetched User List!", userList:[] }, status: :ok
  end

  def impersonate
  #   Logic For Impersonate
  render json: { message: "Successfully Impersonated User!", newjwt:"token" }, status: :ok
  end

end
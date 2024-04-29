class Api::V1::ImpersonateController < ApplicationController

  # Fetches users to impersonate whose name match the passed parameter
  def get_users_list
    users = current_user.get_available_users(params[:user_name])
    render json: { message: "Successfully Fetched User List!", userList:users, success:true }, status: :ok
  end

  def user_is_impersonatable?
    impersonate_user = User.find_by(id: params[:impersonate_id])
    if impersonate_user
      return current_user.can_impersonate? impersonate_user
    end
    false
  end

  # Impersonates a new user and returns new jwt token
  def impersonate
    unless params[:impersonate_id].present?
      render json: { error: "impersonate_id is required", success:false }, status: :unprocessable_entity
      return
    end

    if user_is_impersonatable?
      impersonate_user = User.find_by(id: params[:impersonate_id])

      payload = { id: impersonate_user.id, name: impersonate_user.name, full_name: impersonate_user.full_name, role: impersonate_user.role.name,
                  institution_id: impersonate_user.institution.id, impersonated:true, original_user: current_user }
      impersonate_user_token = JsonWebToken.encode(payload, 24.hours.from_now)

      render json: { message: "Successfully Impersonated #{impersonate_user.name}!", token:impersonate_user_token, success:true }, status: :ok

    else
      render json: { error: "You do not have permission to impersonate this user", success:false }, status: :forbidden
    end
  end
end

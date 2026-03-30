# frozen_string_literal: true

class RolesController < ApplicationController
  # Handle missing parameters and record not found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :role_not_found

  # Ensure only admins or super admins can perform actions
  before_action :authorize_admin!

  # GET /roles
  def index
    roles = Role.order(:id)
    render json: { data: roles.as_json(only: %i[id name parent_id]) }, status: :ok
  end

  # GET /roles/:id
  def show
    role = Role.find(params[:id])
    render json: { data: role.as_json(only: %i[id name parent_id]) }, status: :ok
  end

  # POST /roles
  def create
    role = Role.new(role_params)
    if role.save
      render json: { data: role.as_json(only: %i[id name parent_id]) }, status: :created
    else
      render json: { errors: role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/:id
  def update
    role = Role.find(params[:id])
    if role.update(role_params)
      render json: { data: role.as_json(only: %i[id name parent_id]) }, status: :ok
    else
      render json: { errors: role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:id
  def destroy
    role = Role.find(params[:id])
    role_name = role.name
    role.destroy
    render json: { message: "Role '#{role_name}' deleted successfully!" }, status: :ok
  end

  # GET /roles/subordinate_roles
  def subordinate_roles
    role = current_user.role
    roles = Role.where(id: role.subordinate_roles)
    render json: { data: roles.as_json(only: %i[id name parent_id]) }, status: :ok
  end

  private

  # Only allow a list of trusted parameters through
  def role_params
    params.require(:role).permit(:name, :parent_id)
  end

  # Admin-only access enforcement
  def authorize_admin!
    unless current_user&.role&.admin? || current_user&.role&.super_admin?
      render json: { error: 'Not Authorized' }, status: :unauthorized
    end
  end

  # Rescue handlers
  def parameter_missing
    render json: { error: 'Required parameter missing' }, status: :unprocessable_entity
  end

  def role_not_found
    render json: { error: "Role with id #{params[:id]} not found" }, status: :not_found
  end
end
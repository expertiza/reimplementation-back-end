class Api::V1::RolesController < ApplicationController
  # rescue_from ActiveRecord::RecordNotFound, with: :role_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def action_allowed?
    has_privileges_of?('Administrator')
  end
  
  # GET /roles
  def index
    roles = Role.order(:id)
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched all roles.", request)
    render json: roles, status: :ok
  end

  # GET /roles/:id
  def show
    role = Role.find(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched role with ID: #{role.id}.", request)
    render json: role, status: :ok
  end

  # POST /roles
  def create
    role = Role.new(role_params)
    if role.save
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Created role with ID: #{role.id}.", request)
      render json: role, status: :created
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to create role. Errors: #{role.errors.full_messages.join(', ')}", request)
      render json: role.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/:id
  def update
    role = Role.find(params[:id])
    if role.update(role_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Updated role with ID: #{role.id}.", request)
      render json: role, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to update role with ID: #{role.id}. Errors: #{role.errors.full_messages.join(', ')}", request)
      render json: role.errors, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:ids
  def destroy
    role = Role.find(params[:id])
    role_name = role.name
    role.destroy
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Deleted role with ID: #{role.id}, Name: #{role_name}.", request)
    render json: { message: "Role #{role_name} with id #{params[:id]} deleted successfully!" }, status: :no_content
  end

  def subordinate_roles
    role = current_user.role
    roles = role.subordinate_roles
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched subordinate roles for role ID: #{role.id}.", request)
    render json: roles, status: :ok
  end

  private

  # Only allow a list of trusted parameters through.
  def role_params
    params.require(:role).permit(:id, :name, :parent_id)
  end

  # def role_not_found
  #   render json: { error: "Role with id #{params[:id]} not found" }, status: :not_found
  # end

  def parameter_missing
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Parameter missing.", request)
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

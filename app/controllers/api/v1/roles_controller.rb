class Api::V1::RolesController < ApplicationController
  # rescue_from ActiveRecord::RecordNotFound, with: :role_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def action_allowed?
    current_user_has_admin_privileges?
  end
  
  # GET /roles
  def index
    roles = Role.order(:id)
    render json: roles, status: :ok
  end

  # GET /roles/:id
  def show
    role = Role.find(params[:id])
    render json: role, status: :ok
  end

  # POST /roles
  def create
    role = Role.new(role_params)
    if role.save
      render json: role, status: :created
    else
      render json: role.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/:id
  def update
    role = Role.find(params[:id])
    if role.update(role_params)
      render json: role, status: :ok
    else
      render json: role.errors, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:ids
  def destroy
    role = Role.find(params[:id])
    role_name = role.name
    role.destroy
    render json: { message: "Role #{role_name} with id #{params[:id]} deleted successfully!" }, status: :no_content
  end

  def subordinate_roles
    role = current_user.role
    roles = role.subordinate_roles
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
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

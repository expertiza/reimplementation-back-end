class Api::V1::RolesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :role_not_found
  # GET /roles
  def index
    @roles = Role.order(:name)
    render json: @roles.map { |role| role.slice(:id, :name, :parent_id) }
  end

  # GET /roles/:id
  def show
    @role = Role.find(params[:id])
    render json: @role.slice(:name, :parent_id)
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /roles
  def create
    @role = Role.new(role_params)
    if @role.save
      render json: @role.slice(:name, :parent_id), status: :created
    else
      render json: @role.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/:id
  def update
    @role = Role.find(params[:id])
    if @role.update(role_params)
      render json: @role.slice(:id, :name, :parent_id)
    else
      render json: @role.errors, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:ids
  def destroy
    @role = Role.find(params[:id])
    @role.destroy
  end

  private

  # Only allow a list of trusted parameters through.
  def role_params
    params.require(:role).permit(:name, :parent_id, :default_page_id)
  end

  def role_not_found
    render json: { error: "Role with id #{params[:id]} not found" }, status: :not_found
  end
end
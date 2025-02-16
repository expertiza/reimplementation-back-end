class Api::V1::InstitutionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :institution_not_found
  def action_allowed?
    has_role?('Instructor')
  end
  # GET /institutions
  def index
    @institutions = Institution.all
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched all institutions.", request)
    render json: @institutions, status: :ok
  end

  # GET /institutions/:id
  def show
    @institution = Institution.find(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched institution with ID: #{@institution.id}.", request)
    render json: @institution, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Institution not found with ID: #{params[:id]}. Error: #{e.message}", request)
    render json: { error: e.message }, status: :not_found
  end

  # POST /institutions
  def create
    @institution = Institution.new(institution_params)
    if @institution.save
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Created institution with ID: #{@institution.id}.", request)
      render json: @institution, status: :created
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to create institution. Errors: #{@institution.errors.full_messages.join(', ')}", request)
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /institutions/:id
  def update
    @institution = Institution.find(params[:id])
    if @institution.update(institution_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Updated institution with ID: #{@institution.id}.", request)
      render json: @institution, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to update institution with ID: #{@institution.id}. Errors: #{@institution.errors.full_messages.join(', ')}", request)
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # DELETE /institutions/:id
  def destroy
    @institution = Institution.find(params[:id])
    @institution.destroy
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Deleted institution with ID: #{@institution.id}.", request)
    render json: { message: 'Institution deleted' }, status: :ok
  end

  private

  # Only allow a list of trusted parameters through.
  def institution_params
    params.require(:institution).permit(:id, :name)
  end

  def institution_not_found
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Institution not found with ID: #{params[:id]}.", request)
    render json: { error: 'Institution not found' }, status: :not_found
  end
end
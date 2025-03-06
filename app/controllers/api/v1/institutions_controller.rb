class Api::V1::InstitutionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :institution_not_found
  def action_allowed?
    has_role?('Instructor')
  end
  # GET /institutions
  def index
    @institutions = Institution.all
    render json: @institutions, status: :ok
  end

  # GET /institutions/:id
  def show
    @institution = Institution.find(params[:id])
    render json: @institution, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /institutions
  def create
    @institution = Institution.new(institution_params)
    if @institution.save
      render json: @institution, status: :created
    else
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /institutions/:id
  def update
    @institution = Institution.find(params[:id])
    if @institution.update(institution_params)
      render json: @institution, status: :ok
    else
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # DELETE /institutions/:id
  def destroy
    @institution = Institution.find(params[:id])
    @institution.destroy
    render json: { message: I18n.t('institution.deleted') }, status: :ok
  end

  private

  # Only allow a list of trusted parameters through.
  def institution_params
    params.require(:institution).permit(:id, :name)
  end

  def institution_not_found
    render json: { error: I18n.t('institution.not_found') }, status: :not_found
  end
end
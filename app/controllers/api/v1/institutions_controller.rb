class Api::V1::InstitutionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :institution_not_found
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
      render json: @institution, status: :created, location: @institution
    else
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /institutions/:id
  def update
    @institution = Institution.find(params[:id])
    if @institution.update(institution_params)
      render json: @institution, status: :ok, location: @institution
    else
      render json: @institution.errors, status: :unprocessable_entity
    end
  end

  # DELETE /institutions/:id
  def destroy
    @institution = Institution.find(params[:id])
    @institution.destroy
    render json: { message: 'Institution deleted' }, status: :ok
  end

  private

  # Only allow a list of trusted parameters through.
  def institution_params
    params.require(:institution).permit(:name)
  end

  def institution_not_found
    render json: { error: 'Institution not found' }, status: :not_found
  end
end
class DutiesController < ApplicationController
  include AuthorizationHelper
  
  #before_action :authenticate_user!
  before_action :action_allowed!, only: [:index, :show, :create, :update, :destroy]
  before_action :set_duty, only: [:show, :update, :destroy]

  # GET /duties
  # /duties?mine=true to get only current user's duties
  def index
    duties = Duty.all
    duties = duties.where('name LIKE ?', "%#{params[:search]}%") if params[:search].present?
    if params[:mine].present? && current_user
      duties = duties.where(instructor_id: current_user.id)
    end
    render json: duties
  end

  # GET /duties/:id
  def show
    if @duty.private && @duty.instructor_id != current_user&.id
      render json: { error: 'Not authorized to view this duty' }, status: :forbidden
    else
      render json: @duty
    end
  end

  # POST /duties
  def create
    @duty = Duty.new(duty_params)
    @duty.instructor_id = current_user.id if current_user
    if @duty.save
      render json: @duty, status: :created
    else
      render json: @duty.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /duties/:id
  def update
    if @duty.instructor_id != current_user&.id
      render json: { error: 'Not authorized to update this duty' }, status: :forbidden
    elsif @duty.update(duty_params)
      render json: @duty
    else
      render json: @duty.errors, status: :unprocessable_entity
    end
  end

  # DELETE /duties/:id
  def destroy
    if @duty.instructor_id != current_user&.id
      render json: { error: 'Not authorized to delete this duty' }, status: :forbidden
    else
      @duty.destroy
      head :no_content
    end
  end

  def accessible_duties
    duties = Duty.where(private: false) # Start with all public duties

    if current_user.present?
      # Add private duties created by the current user
      duties = duties.or(Duty.where(instructor_id: current_user.id))

      # Add private duties for courses where the user is the instructor or TA
      course_ids = Course.all.select { |course| current_user_instructs_or_tas_course?(course.id) }.map(&:id)
      duties = duties.or(Duty.joins("LEFT JOIN courses ON duties.instructor_id = courses.instructor_id").where("courses.id IN (?)", course_ids))
    end

    render json: duties
  end

  private

  def set_duty
    @duty = Duty.find(params[:id])
  end

  def duty_params
    params.require(:duty).permit(:name, :instructor_id, :private)
  end

  def action_allowed!
    unless current_user_has_instructor_privileges?
      render json: { error: 'Not authorized' }, status: :forbidden
    end
  end
end
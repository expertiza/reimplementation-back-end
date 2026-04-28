class AssignmentsDutiesController < ApplicationController
  include Authorization
  #before_action :authenticate_user!
  before_action :action_allowed!, only: [:create, :destroy, :update_limit]
  before_action :set_assignment
  before_action :set_assignment_duty, only: [:update_limit]

  # GET /assignments/:assignment_id/duties
  def index
    render json: serialized_assignment_duties
  end

  # POST /assignments/:assignment_id/duties
  def create
    duty = Duty.find(params[:duty_id])
    assignment_duty = @assignment.assignments_duties.find_or_initialize_by(duty_id: duty.id)
    assignment_duty.max_members_for_duty ||= 1

    if assignment_duty.save
      render json: serialized_assignment_duties, status: :ok
    else
      render json: assignment_duty.errors, status: :unprocessable_entity
    end
  end

  # DELETE /assignments/:assignment_id/duties/:id
  def destroy
    duty = Duty.find(params[:id])
    @assignment.duties.delete(duty)
    head :no_content
  end

  # PATCH /assignments/:assignment_id/duties/:id/limit
  def update_limit
    if @assignment_duty.update(limit_params)
      render json: serialize_assignment_duty(@assignment_duty), status: :ok
    else
      render json: @assignment_duty.errors, status: :unprocessable_entity
    end
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def set_assignment_duty
    @assignment_duty = @assignment.assignments_duties.find_by(duty_id: params[:id])
    return if @assignment_duty

    render json: { error: 'Duty is not assigned to this assignment' }, status: :not_found
  end

  def limit_params
    params.permit(:max_members_for_duty)
  end

  def serialized_assignment_duties
    @assignment.assignments_duties.includes(:duty).map do |assignment_duty|
      serialize_assignment_duty(assignment_duty)
    end
  end

  def serialize_assignment_duty(assignment_duty)
    {
      duty_id: assignment_duty.duty_id,
      duty_name: assignment_duty.duty&.name,
      max_members_for_duty: assignment_duty.max_members_for_duty
    }
  end

  def action_allowed!
    unless current_user_has_instructor_privileges?
      render json: { error: 'Not authorized' }, status: :forbidden
    end
  end
end

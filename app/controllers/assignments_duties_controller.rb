class AssignmentsDutiesController < ApplicationController
  include AuthorizationHelper
  #before_action :authenticate_user!
  before_action :action_allowed!, only: [:create, :destroy]
  # GET /assignments/:assignment_id/duties
  def index
    assignment = Assignment.find(params[:assignment_id])
    render json: assignment.duties
  end

  # POST /assignments/:assignment_id/duties
  def create
    assignment = Assignment.find(params[:assignment_id])
    duty = Duty.find(params[:duty_id])
    assignment.duties << duty unless assignment.duties.include?(duty)
    render json: assignment.duties
  end

  # DELETE /assignments/:assignment_id/duties/:id
  def destroy
    assignment = Assignment.find(params[:assignment_id])
    duty = Duty.find(params[:id])
    assignment.duties.delete(duty)
    head :no_content
  end

  private

  def action_allowed!
    unless current_user_has_instructor_privileges?
      render json: { error: 'Not authorized' }, status: :forbidden
    end
  end
end

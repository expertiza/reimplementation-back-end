class Api::V1::AssignmentsController < ApplicationController
  # GET /api/v1/assignments
  def index
    assignments = Assignment.all
    render json: assignments
  end

  # GET /api/v1/assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    render json: assignment
  end

  # POST /api/v1/assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      render json: assignment, status: :created
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  def edit
    #user_timezone_specified
    #edit_params_setting
    #assignment_staggered_deadline?
    #update_due_date
    #check_questionnaires_usage
    # @due_date_all = update_nil_dd_deadline_name(@due_date_all)
    # @due_date_all = update_nil_dd_description_url(@due_date_all)
    #unassigned_rubrics_warning
    #path_warning_and_answer_tag
    #update_assignment_badges
    # @assigned_badges = @assignment_form.assignment.badges
    # @badges = Badge.all
    # @use_bookmark = @assignment.use_bookmark
    # @duties = Duty.where(assignment_id: @assignment_form.assignment.id)
  end

  # PATCH/PUT /api/v1/assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    if assignment.update(assignment_params)
      render json: assignment, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/assignments/:id
  def destroy
    assignment = Assignment.find(params[:id])
    assignment.destroy
    head :no_content
  end

  private

  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(:title, :description)
  end
end

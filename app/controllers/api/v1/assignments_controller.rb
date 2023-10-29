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

  def add_participant
    assignment = Assignment.find(params[:assignment_id])
    assignment.add_participant(true,true,true)
  end

  def remove_participant
    #user = User.find_by(id: @current_user.id)
    user = User.find_by(id: 4)
    assignment = Assignment.find(params[:assignment_id])
    assignment.remove_participant(assignment.id, user.id)
  end

  def remove_assignment_from_course
    assignment = Assignment.find(params[:assignment_id])
    assignment.remove_assignment_from_course(assignment.id)
  end

  def assign_courses_to_assignment
    assignment = Assignment.find(params[:assignment_id])
    course = Course.find(params[:course_id])
    assignment.assign_courses_to_assignment(assignment.id, course.id)
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
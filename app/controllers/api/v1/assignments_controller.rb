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
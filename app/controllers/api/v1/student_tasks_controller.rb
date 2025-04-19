class Api::V1::StudentTasksController < ApplicationController
  # List retrieves all student tasks associated with the current logged-in user.
  def action_allowed?
    has_privileges_of?('Student')
  end

  # Retrieves all tasks that belong to the current user.
  def list
    @student_tasks = StudentTask.from_user(current_user)
    render json: @student_tasks, status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  # The view function retrieves a student task based on a participant's ID.
  def view
    @student_task = StudentTask.from_participant_id(params[:id])
    render json: @student_task, status: :ok
  end
end

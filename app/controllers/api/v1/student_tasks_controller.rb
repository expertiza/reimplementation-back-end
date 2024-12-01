class Api::V1::StudentTasksController < ApplicationController

  # List retrieves all student tasks associated with the current logged-in user.
  def list
    # Retrieves all tasks that belong to the current user.
    @student_tasks = StudentTask.from_user(current_user)
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched student tasks for user ID: #{current_user.id}.", request)
    # Render the list of student tasks as JSON.
    render json: @student_tasks, status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  # The view function retrieves a student task based on a participant's ID.
  # It is meant to provide an endpoint where tasks can be queried based on participant ID.
  def view
    # Retrieves the student task where the participant's ID matches the provided parameter.
    # This function will be used for clicking on a specific student task to "view" its details.
    @student_task = StudentTask.from_participant_id(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched student task for participant ID: #{params[:id]}.", request)
    # Render the found student task as JSON.
    render json: @student_task, status: :ok
  end

end

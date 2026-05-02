class StudentTasksController < ApplicationController

  # List retrieves all student tasks associated with the current logged-in user.
  def action_allowed?
    current_user_has_student_privileges?
  end
  def list
    # Retrieves all tasks that belong to the current user.
    @student_tasks = StudentTask.from_user(current_user)
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
    # Render the found student task as JSON.
    render json: @student_task, status: :ok
  end

  def rubric_for
    response_map = ResponseMap.find(params[:response_map_id])
    assignment_questionnaire = response_map
                               .response_assignment
                               .assignment_questionnaire_for_response_map(response_map, round: rubric_round)

    if assignment_questionnaire.nil?
      render json: { error: 'No review rubric found for this response map.' }, status: :not_found
      return
    end

    render json: {
      assignment_questionnaire_id: assignment_questionnaire.id,
      questionnaire_id: assignment_questionnaire.questionnaire_id,
      questionnaire_name: assignment_questionnaire.questionnaire&.name,
      project_topic_id: assignment_questionnaire.project_topic_id,
      used_in_round: assignment_questionnaire.used_in_round
    }, status: :ok
  end

  private

  def rubric_round
    return nil if params[:round].blank?

    params[:round].to_i
  end
end

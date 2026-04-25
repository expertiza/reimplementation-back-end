# frozen_string_literal: true

class ResponsesController < ApplicationController
  prepend_before_action :set_response, only: %i[show update]
  before_action :find_and_authorize_map_for_create, only: %i[create]

  def action_allowed?
    case action_name
    when "create"
      true  # auth already handled by prepend_before_action above
    when "show", "update"
      @response && @response.map.reviewer.user_id == current_user.id
    else
      true
    end
  end

  def show
    render json: {
      response_id: @response.id,
      map_id: @response.map_id,
      task_type: @response.map.type,
      submitted: @response.is_submitted,
      additional_comment: @response.additional_comment
    }
  end

  def create
    return unless enforce_task_order!(@map)

    round = (params[:round].presence || 1).to_i
    response = Response.where(map_id: @map.id, round: round)
                       .order(:created_at)
                       .last || Response.new(map_id: @map.id, round: round)

    if params[:content].present? || params[:additional_comment].present?
      response.additional_comment = params[:content].presence || params[:additional_comment]
    end

    if response.save
      render json: { response_id: response.id, map_id: @map.id, round: response.round }, status: :created
    else
      render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return unless enforce_task_order!(@response.map)

    if @response.update(response_update_params)
      render json: {
        response_id: @response.id,
        map_id: @response.map_id,
        submitted: @response.is_submitted,
        additional_comment: @response.additional_comment
      }, status: :ok
    else
      render json: { errors: @response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_response
    @response = Response.find(params[:id])
  end

  # Runs before action_allowed? — handles both existence and authorization for create
  def find_and_authorize_map_for_create
    @map = ResponseMap.find_by(id: params[:response_map_id])
    unless @map
      render json: { error: "ResponseMap not found" }, status: :not_found
      return
    end

    unless @map.reviewer.user_id == current_user.id
      render json: { error: "You are not authorized to create this responses" }, status: :forbidden
    end
  end
 

  def response_update_params
    p = params.permit(:is_submitted, :additional_comment, :content, :round)
    p[:additional_comment] = p[:content] if p[:content].present?
    p.delete(:content)
    p
  end

  def enforce_task_order!(map)
    participant = map.reviewer
    unless participant.user_id == current_user.id
      render json: { error: "Unauthorized" }, status: :forbidden
      return false
    end

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    unless team_participant
      render json: { error: "TeamsParticipant not found for reviewer" }, status: :forbidden
      return false
    end

    tasks = build_tasks(participant.assignment, participant, team_participant)
    current_task = find_task_for_map(tasks, map.id)
    unless current_task
      render json: { error: "Response map is not a respondable task for this participant" }, status: :forbidden
      return false
    end

    unless prior_tasks_complete?(tasks, current_task)
      render json: { error: "Complete previous task first" }, status: :precondition_failed
      return false
    end

    true
  end

  def build_tasks(assignment, participant, team_participant)
    duty = resolve_duty(team_participant, participant)
    tasks = []

    review_maps = ReviewResponseMap.where(
      reviewer_id: participant.id,
      reviewed_object_id: assignment.id
    )
    quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow
    has_existing_quiz_maps = QuizResponseMap.where(reviewer_id: participant.id).exists?

    if review_maps.any?
      review_maps.each do |review_map|
        if (duty.nil? || duty_allows_quiz?(duty)) && (quiz_questionnaire || has_existing_quiz_maps)
          tasks << StudentTasksController::QuizTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end

        if duty.nil? || duty_allows_review?(duty)
          tasks << StudentTasksController::ReviewTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end
      end
    elsif duty_allows_quiz?(duty) && quiz_questionnaire
      tasks << StudentTasksController::QuizTaskItem.new(
        assignment: assignment,
        team_participant: team_participant,
        review_map: nil
      )
    end

    tasks
  end

  def resolve_duty(team_participant, participant)
    Duty.find_by(id: team_participant.duty_id) || Duty.find_by(id: participant.duty_id)
  end

  def find_task_for_map(tasks, map_id)
    tasks.find do |task|
      response_map = task.response_map
      response_map && response_map.id.to_i == map_id.to_i
    end
  end

  def prior_tasks_complete?(tasks, current_task)
    tasks.take_while { |task| task != current_task }.all?(&:completed?)
  end

  def duty_allows_review?(duty)
    return false if duty.nil?

    duty.name.in?(%w[participant reader reviewer mentor])
  end

  def duty_allows_quiz?(duty)
    return false if duty.nil?

    duty.name.in?(%w[participant reader mentor])
  end
end
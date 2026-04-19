class AssignmentQuestionnairesController < ApplicationController
  before_action :set_assignment_questionnaire, only: %i[update destroy]

  def action_allowed?
    assignment_id = assignment_id_for_authorization
    return false if assignment_id.blank?

    current_user_has_admin_privileges? || current_user_teaching_staff_of_assignment?(assignment_id)
  end

  def index
    if params[:assignment_id].blank?
      render json: { error: 'assignment_id is required' }, status: :bad_request
      return
    end

    mappings = AssignmentQuestionnaire.includes(:questionnaire, :project_topic)
    mappings = mappings.where(assignment_id: params[:assignment_id])
    mappings = mappings.where(project_topic_id: params[:project_topic_id]) if params[:project_topic_id].present?

    render json: mappings.map { |mapping| serialize_mapping(mapping) }, status: :ok
  end

  def create
    mapping = AssignmentQuestionnaire.new(assignment_questionnaire_params)

    if mapping.save
      render json: serialize_mapping(mapping), status: :created
    else
      render json: { errors: mapping.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @assignment_questionnaire.update(assignment_questionnaire_params)
      render json: serialize_mapping(@assignment_questionnaire), status: :ok
    else
      render json: { errors: @assignment_questionnaire.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment_questionnaire.destroy
    head :no_content
  end

  private

  def set_assignment_questionnaire
    @assignment_questionnaire = AssignmentQuestionnaire.find(params[:id])
  end

  def assignment_id_for_authorization
    case params[:action]
    when 'index'
      params[:assignment_id]
    when 'create'
      params.dig(:assignment_questionnaire, :assignment_id)
    when 'update', 'destroy'
      AssignmentQuestionnaire.find_by(id: params[:id])&.assignment_id
    end
  end

  def assignment_questionnaire_params
    params.require(:assignment_questionnaire).permit(
      :assignment_id,
      :questionnaire_id,
      :project_topic_id,
      :used_in_round,
      :notification_limit,
      :questionnaire_weight
    )
  end

  def serialize_mapping(mapping)
    {
      id: mapping.id,
      assignment_id: mapping.assignment_id,
      questionnaire_id: mapping.questionnaire_id,
      questionnaire_name: mapping.questionnaire&.name,
      project_topic_id: mapping.project_topic_id,
      project_topic_name: mapping.project_topic&.topic_name,
      used_in_round: mapping.used_in_round,
      notification_limit: mapping.notification_limit,
      questionnaire_weight: mapping.questionnaire_weight
    }
  end
end

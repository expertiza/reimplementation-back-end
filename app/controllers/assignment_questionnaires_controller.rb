class AssignmentQuestionnairesController < ApplicationController
  include ReviewResetHandler

  REVIEW_RESET_ATTRIBUTES = %i[assignment_id questionnaire_id project_topic_id used_in_round].freeze

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
    reset_plan = build_review_reset_plan_for_contexts(
      [review_reset_context(mapping, reset_reason: 'mapping_created')]
    )

    if mapping.save
      apply_review_reset_plan(reset_plan)
      render json: serialize_mapping(mapping), status: :created
    else
      render json: { errors: mapping.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    reset_context = review_reset_context(@assignment_questionnaire, reset_reason: 'mapping_updated')
    reset_plan = build_review_reset_plan_for_contexts([reset_context])

    if @assignment_questionnaire.update(assignment_questionnaire_params)
      apply_review_reset_plan(reset_plan) if rubric_mapping_changed?(reset_context, @assignment_questionnaire)
      render json: serialize_mapping(@assignment_questionnaire), status: :ok
    else
      render json: { errors: @assignment_questionnaire.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    reset_context = review_reset_context(@assignment_questionnaire, reset_reason: 'mapping_deleted')
    reset_plan = build_review_reset_plan_for_contexts([reset_context])

    @assignment_questionnaire.destroy
    apply_review_reset_plan(reset_plan)
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

  def rubric_mapping_changed?(old_context, mapping)
    REVIEW_RESET_ATTRIBUTES.any? { |attribute| old_context[attribute] != mapping.public_send(attribute) }
  end

  def reset_reviews_for_mapping(context)
    context = context.merge(reset_reason: context[:reset_reason] || 'mapping_updated')
    apply_review_reset_plan(build_review_reset_plan_for_contexts([context]))
  end
end

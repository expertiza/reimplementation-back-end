class AssignmentQuestionnairesController < ApplicationController
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

    if mapping.save
      render json: serialize_mapping(mapping), status: :created
    else
      render json: { errors: mapping.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    reset_context = review_reset_context(@assignment_questionnaire)

    if @assignment_questionnaire.update(assignment_questionnaire_params)
      reset_reviews_for_mapping(reset_context) if rubric_mapping_changed?(reset_context, @assignment_questionnaire)
      render json: serialize_mapping(@assignment_questionnaire), status: :ok
    else
      render json: { errors: @assignment_questionnaire.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    reset_context = review_reset_context(@assignment_questionnaire)

    @assignment_questionnaire.destroy
    reset_reviews_for_mapping(reset_context)
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

  def review_reset_context(mapping)
    {
      assignment_id: mapping.assignment_id,
      questionnaire_id: mapping.questionnaire_id,
      project_topic_id: mapping.project_topic_id,
      used_in_round: mapping.used_in_round,
      review_mapping: mapping.questionnaire&.questionnaire_type == 'ReviewQuestionnaire'
    }
  end

  def rubric_mapping_changed?(old_context, mapping)
    REVIEW_RESET_ATTRIBUTES.any? { |attribute| old_context[attribute] != mapping.public_send(attribute) }
  end

  def reset_reviews_for_mapping(context)
    return unless context[:review_mapping]

    assignment = Assignment.find_by(id: context[:assignment_id])
    return unless assignment

    review_maps = review_maps_for_mapping(context)
    responses = Response.where(map_id: review_maps.select(:id))
    responses = responses.where(round: context[:used_in_round]) if context[:used_in_round].present?

    affected_map_ids = responses.distinct.pluck(:map_id)
    return if affected_map_ids.empty?

    responses.destroy_all
    notify_reviewers_to_redo(review_maps.where(id: affected_map_ids), assignment)
  end

  def review_maps_for_mapping(context)
    review_maps = ReviewResponseMap.where(reviewed_object_id: context[:assignment_id])
    return review_maps if context[:project_topic_id].blank?

    topic_team_ids = SignedUpTeam.confirmed.where(project_topic_id: context[:project_topic_id]).select(:team_id)
    review_maps.where(reviewee_id: topic_team_ids)
  end

  def notify_reviewers_to_redo(review_maps, assignment)
    review_maps.includes(reviewer: :user).find_each do |review_map|
      next if review_map.reviewer&.user&.email.blank?

      RubricUpdateMailer.with(response_map: review_map, assignment: assignment)
                        .review_redo_notification
                        .deliver_later
    end
  end
end

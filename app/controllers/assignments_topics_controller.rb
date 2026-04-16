class AssignmentsTopicsController < ApplicationController
  before_action :set_assignment
  before_action :action_allowed!, only: :rubrics

  def rubrics
    if request.get?
      render json: rubric_payload, status: :ok
    else
      update_topic_rubrics!
      render json: rubric_payload, status: :ok
    end
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id] || params[:id])
  end

  def rubric_payload
    questionnaire_type = requested_questionnaire_type
    {
      assignment_id: @assignment.id,
      vary_by_topic: @assignment.vary_by_topic,
      vary_by_round: @assignment.vary_by_round,
      questionnaire_type: questionnaire_type,
      rounds: rubric_rounds,
      available_rubrics: @assignment.available_rubrics_for(user: current_user, questionnaire_type:).map do |rubric|
        { id: rubric.id, name: rubric.name, questionnaire_type: rubric.questionnaire_type, private: rubric.private }
      end,
      default_rubrics: rubric_rounds.map do |round|
        default_mapping = @assignment.default_rubric_mapping_for(questionnaire_type:, round:)
        {
          used_in_round: round,
          questionnaire_id: default_mapping&.questionnaire_id,
          questionnaire_name: default_mapping&.questionnaire&.name
        }
      end,
      topics: @assignment.project_topics.order(:id).map do |topic|
        {
          id: topic.id,
          topic_identifier: topic.topic_identifier,
          topic_name: topic.topic_name,
          rubric_assignments: rubric_rounds.map do |round|
            specific_mapping = topic.specific_rubric_mapping(questionnaire_type:, round:)
            effective_mapping = @assignment.rubric_mapping_for(questionnaire_type:, round:, topic:)
            {
              used_in_round: round,
              questionnaire_id: specific_mapping&.questionnaire_id,
              questionnaire_name: specific_mapping&.questionnaire&.name,
              effective_questionnaire_id: effective_mapping&.questionnaire_id,
              effective_questionnaire_name: effective_mapping&.questionnaire&.name,
              has_specific_rubric: specific_mapping.present?
            }
          end
        }
      end
    }
  end

  def update_topic_rubrics!
    ActiveRecord::Base.transaction do
      @assignment.update!(assignment_topic_params) if assignment_topic_params.present?

      rubric_mappings_params.each do |mapping|
        topic = @assignment.project_topics.find(mapping[:topic_id])
        topic.assign_rubric!(
          questionnaire_type: requested_questionnaire_type,
          questionnaire_id: mapping[:questionnaire_id],
          used_in_round: mapping[:used_in_round]
        )
      end
    end
  end

  def rubric_mappings_params
    raw_mappings = params[:rubric_mappings]
    return [] if raw_mappings.blank?

    mappings =
      if raw_mappings.is_a?(ActionController::Parameters)
        raw_mappings.values
      else
        Array.wrap(raw_mappings)
      end

    mappings.map do |mapping|
      mapping.is_a?(ActionController::Parameters) ?
        mapping.permit(:topic_id, :questionnaire_id, :used_in_round) :
        ActionController::Parameters.new(mapping).permit(:topic_id, :questionnaire_id, :used_in_round)
    end
  end

  def assignment_topic_params
    assignment_params = params[:assignment]
    return ActionController::Parameters.new({}).permit(:vary_by_topic, :vary_by_round) if assignment_params.blank?

    assignment_params.permit(:vary_by_topic, :vary_by_round)
  end

  def requested_questionnaire_type
    params[:questionnaire_type].presence || 'ReviewQuestionnaire'
  end

  def rubric_rounds
    return [nil] unless @assignment.vary_by_round

    round_count = [@assignment.num_review_rounds, 1].max
    (1..round_count).to_a
  end

  def action_allowed!
    return if current_user_has_admin_privileges?
    return if current_user_instructs_assignment?(@assignment)
    return if @assignment.course && current_user_is_a?('Teaching Assistant') && current_user_has_ta_mapping_for_assignment?(@assignment)

    render json: { error: 'Not authorized' }, status: :forbidden
  end
end

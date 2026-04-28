# frozen_string_literal: true

require 'set'

module ReviewResetHandler
  extend ActiveSupport::Concern

  private

  def review_questionnaire?(questionnaire)
    questionnaire&.questionnaire_type == 'ReviewQuestionnaire'
  end

  def review_reset_context(mapping, reset_reason:)
    {
      assignment_id: mapping.assignment_id,
      questionnaire_id: mapping.questionnaire_id,
      project_topic_id: mapping.project_topic_id,
      used_in_round: mapping.used_in_round,
      review_mapping: review_questionnaire?(mapping.questionnaire),
      reset_reason: reset_reason
    }
  end

  def build_review_reset_plan_for_contexts(contexts)
    processed_response_ids = Set.new

    Array(contexts).filter_map do |context|
      next unless context[:review_mapping]

      assignment = Assignment.find_by(id: context[:assignment_id])
      next unless assignment

      review_maps = review_maps_for_mapping_context(context)
      responses = responses_for_review_maps(review_maps, context[:used_in_round])
                  .includes(scores: :item)
                  .to_a
                  .reject { |response| processed_response_ids.include?(response.id) }

      next if responses.empty?

      processed_response_ids.merge(responses.map(&:id))

      {
        assignment: assignment,
        response_ids: responses.map(&:id),
        response_map_ids: responses.map(&:map_id).uniq,
        archives: responses.map { |response| archive_attributes_for_response(response, context) }
      }
    end
  end

  def build_review_reset_plan_for_questionnaire(questionnaire, reset_reason:)
    contexts = AssignmentQuestionnaire
               .includes(:questionnaire)
               .where(questionnaire_id: questionnaire.id)
               .map { |mapping| review_reset_context(mapping, reset_reason: reset_reason) }

    build_review_reset_plan_for_contexts(contexts)
  end

  def apply_review_reset_plan(plan)
    Array(plan).each do |entry|
      entry[:archives].each do |archive_attributes|
        ReviewResetArchive.create!(archive_attributes)
      end

      review_maps = ReviewResponseMap.where(id: entry[:response_map_ids])
      notify_reviewers_to_redo(review_maps, entry[:assignment])
      Response.where(id: entry[:response_ids]).destroy_all
    end
  end

  def review_maps_for_mapping_context(context)
    review_maps = ReviewResponseMap.where(reviewed_object_id: context[:assignment_id])
    return review_maps if context[:project_topic_id].blank?

    topic_team_ids = SignedUpTeam.confirmed.where(project_topic_id: context[:project_topic_id]).select(:team_id)
    review_maps.where(reviewee_id: topic_team_ids)
  end

  def responses_for_review_maps(review_maps, used_in_round)
    responses = Response.where(map_id: review_maps.select(:id))
    return responses if used_in_round.blank?

    responses.where(round: used_in_round)
  end

  def archive_attributes_for_response(response, context)
    assignment_questionnaire =
      response.response_assignment.assignment_questionnaire_for_response_map(response.map, round: response.round)
    questionnaire = assignment_questionnaire&.questionnaire

    {
      response_id: response.id,
      map_id: response.map_id,
      assignment_id: context[:assignment_id],
      questionnaire_id: questionnaire&.id || context[:questionnaire_id],
      project_topic_id: context[:project_topic_id],
      round: response.round,
      reviewer_id: response.map.reviewer_id,
      reviewee_id: response.map.reviewee_id,
      reset_reason: context[:reset_reason],
      snapshot_data: {
        response: {
          id: response.id,
          map_id: response.map_id,
          round: response.round,
          version_num: response.version_num,
          additional_comment: response.additional_comment,
          is_submitted: response.is_submitted,
          created_at: response.created_at,
          updated_at: response.updated_at
        },
        questionnaire: questionnaire && {
          id: questionnaire.id,
          name: questionnaire.name,
          questionnaire_type: questionnaire.questionnaire_type
        },
        reviewer: {
          id: response.map.reviewer_id,
          name: response.reviewer&.user&.name
        },
        reviewee: {
          id: response.map.reviewee_id,
          name: response.reviewee&.name
        },
        answers: response.scores.map do |answer|
          {
            id: answer.id,
            item_id: answer.item_id,
            item_type: answer.item&.question_type,
            item_text: answer.item&.txt,
            weight: answer.item&.weight,
            answer: answer.answer,
            comments: answer.comments
          }
        end
      }
    }
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

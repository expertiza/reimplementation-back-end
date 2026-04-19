# frozen_string_literal: true

module TopicBasedRubricLookup
  extend ActiveSupport::Concern

  def assignment_questionnaire_for_response_map(response_map, round:)
    return assignment_questionnaires.find_by(used_in_round: round) unless response_map.is_a?(ReviewResponseMap)

    review_assignment_questionnaire(response_map, round) || assignment_questionnaires.find_by(used_in_round: round)
  end

  private

  def review_assignment_questionnaire(response_map, round)
    topic_id = vary_by_topic ? confirmed_topic_id_for(response_map.reviewee) : nil

    rubric_lookup_order(topic_id, round).each do |project_topic_id, used_in_round|
      rubric = review_assignment_questionnaires.find_by(
        project_topic_id: project_topic_id,
        used_in_round: used_in_round
      )
      return rubric if rubric
    end

    nil
  end

  def confirmed_topic_id_for(reviewee)
    return unless reviewee.is_a?(Team)

    SignedUpTeam.confirmed
                .joins(:project_topic)
                .find_by(
                  team_id: reviewee.id,
                  project_topics: { assignment_id: id }
                )
                &.project_topic_id
  end

  def rubric_lookup_order(topic_id, round)
    order = []
    order << [topic_id, round] if topic_id.present? && !round.nil?
    order << [topic_id, nil] if topic_id.present?
    order << [nil, round] unless round.nil?
    order << [nil, nil]
    order.uniq
  end

  def review_assignment_questionnaires
    assignment_questionnaires
      .joins(:questionnaire)
      .where(questionnaires: { questionnaire_type: 'ReviewQuestionnaire' })
  end
end

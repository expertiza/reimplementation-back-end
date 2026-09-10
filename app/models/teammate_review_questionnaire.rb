# frozen_string_literal: true

class TeammateReviewQuestionnaire < Questionnaire
  after_initialize :post_initialization
  @print_name = 'Teammate Review Rubric'

  def post_initialization
    self.display_type = 'Teammate Review'
  end

  def symbol
    'teammate'.to_sym
  end

  def get_assessments_for(participant)
    participant.teammate_reviews
  end

  # Returns submitted responses for the given participant in a specific round.
  # Fetches all TeammateReviewResponseMaps where the participant is the reviewer,
  # then delegates to the shared base-class helper to filter by round and submission status.
  def get_assessments_for_round(participant, round)
    maps = TeammateReviewResponseMap.where(reviewer_id: participant.id)
    filter_submitted_responses_for_round(maps, round)
  end

  # True if any items are Criterion type (rendered as percentage sliders in the UI).
  def has_criterion_items?
    items.any? { |item| item.question_type == 'Criterion' }
  end
end

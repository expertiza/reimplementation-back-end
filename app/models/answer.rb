# frozen_string_literal: true

class Answer < ApplicationRecord
    belongs_to :response
    belongs_to :item

  scope :for_items_and_responses, ->(item_ids, response_ids) { where(item_id: item_ids, response_id: response_ids) }

  scope :taggable_for_assignment, ->(assignment_id, item_ids, type:, threshold: nil) {
    scope = joins(response: :response_map)
      .where(
        item_id:       item_ids,
        responses:     { is_submitted: true },
        response_maps: { reviewed_object_id: assignment_id, type: type }
      )
    scope = scope.where('LENGTH(answers.comments) > ?', threshold) if threshold
    scope
  }
end

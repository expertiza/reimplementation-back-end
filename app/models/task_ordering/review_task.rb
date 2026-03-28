# frozen_string_literal: true

module TaskOrdering
  class ReviewTask < BaseTask
    def task_type
      :review
    end

    def response_map
      review_map
    end
  end
end

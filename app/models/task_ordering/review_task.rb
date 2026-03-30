# frozen_string_literal: true

# ReviewTask represents a review response tied directly to an existing ReviewResponseMap.
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

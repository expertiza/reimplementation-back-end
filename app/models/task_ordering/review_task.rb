module TaskOrdering
  class ReviewTask < BaseTask
    def task_type
      :review
    end

    # Review map already exists (assigned earlier)
    def response_map
      review_map
    end
  end
end
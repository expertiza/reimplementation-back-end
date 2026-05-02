# frozen_string_literal: true

class ReviewTaskItem < StudentTask::BaseTaskItem
  # Labels this task item as a review task.
  def task_type
    :review
  end

  # Uses the existing review response map for this task.
  def response_map
    review_map
  end
end

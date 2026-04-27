# frozen_string_literal: true

class StudentTask::ReviewTaskItem < StudentTask::BaseTaskItem
  def task_type
    :review
  end

  def response_map
    review_map
  end
end

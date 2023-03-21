class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :response

  scope :by_question_for_reviewee_in_round, -> (assignment_id, reviewee_id, q_id, round) do
    joins(response: {map: :reviewer})
      .joins(:question)
      .where("review_maps.reviewed_object_id = ? AND
              review_maps.reviewee_id = ? AND
              answers.question_id = ? AND
              responses.round = ?", assignment_id, reviewee_id, q_id, round)
      .select(:answer, :comments)
  end

  scope :by_question, -> (assignment_id, q_id) do
    joins(response: {map: :reviewer})
      .joins(:question)
      .where("review_maps.reviewed_object_id = ? AND
              answers.question_id = ?", assignment_id, q_id)
      .select(:answer, :comments)
      .distinct
  end

  scope :by_question_for_reviewee, -> (assignment_id, reviewee_id, q_id) do
    joins(response: {map: :reviewer})
      .joins(:question)
      .where("review_maps.reviewed_object_id = ? AND
              review_maps.reviewee_id = ? AND
              answers.question_id = ?", assignment_id, reviewee_id, q_id)
      .select(:answer, :comments)
  end

  scope :by_response, -> (response_id) do
    where(response_id: response_id)
      .order(question_id: :asc)
      .pluck(:answer)
  end
end


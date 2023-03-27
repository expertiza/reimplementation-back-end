# Define a class Answer that inherits from ApplicationRecord
class Answer < ApplicationRecord
  # Define the associations for Answer model
  belongs_to :question
  belongs_to :response

  # Define a scope to select answers for a particular question and round for a given reviewee and assignment
  scope :by_question_for_reviewee_in_round, -> (assignment_id, reviewee_id, q_id, round) do
    joins(response: {map: :reviewer}) # join response, map and reviewer tables
      .joins(:question) # join question table
      .where("review_maps.reviewed_object_id = ? AND
              review_maps.reviewee_id = ? AND
              answers.question_id = ? AND
              responses.round = ?", assignment_id, reviewee_id, q_id, round) # filter results based on given parameters
      .select(:answer, :comments) # select answer and comments columns
  end

  # Define a scope to select distinct answers for a particular question and assignment
  scope :by_question, -> (assignment_id, q_id) do
    joins(response: {map: :reviewer}) # join response, map and reviewer tables
      .joins(:question) # join question table
      .where("review_maps.reviewed_object_id = ? AND
              answers.question_id = ?", assignment_id, q_id) # filter results based on given parameters
      .select(:answer, :comments) # select answer and comments columns
      .distinct # return only distinct results
  end

  # Define a scope to select answers for a particular question and reviewee for a given assignment
  scope :by_question_for_reviewee, -> (assignment_id, reviewee_id, q_id) do
    joins(response: {map: :reviewer}) # join response, map and reviewer tables
      .joins(:question) # join question table
      .where("review_maps.reviewed_object_id = ? AND
              review_maps.reviewee_id = ? AND
              answers.question_id = ?", assignment_id, reviewee_id, q_id) # filter results based on given parameters
      .select(:answer, :comments) # select answer and comments columns
  end

  # Define a scope to select answers for a given response
  scope :by_response, -> (response_id) do
    where(response_id: response_id) # filter results based on given response id
      .order(question_id: :asc) # order results based on question id in ascending order
      .pluck(:answer) # return only answer column
  end
end

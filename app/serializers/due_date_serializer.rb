class DueDateSerializer < ActiveModel::Serializer
  attributes :id, :deadline_type_id, :due_at, :round,
             :submission_allowed_id, :review_allowed_id, :teammate_review_allowed_id

  def deadline_name
    ExpertizaConstants::DeadlineTypes::NAMES[object.deadline_type_id]
  end

  attribute :deadline_name
end

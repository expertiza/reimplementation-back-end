class QuestionnaireSerializer < ActiveModel::Serializer
  attributes :id, :name, :instructor_id, :private, :min_question_score,
             :max_question_score, :questionnaire_type, :display_type,
             :instruction_loc, :created_at, :updated_at

  attribute :instructor

  def instructor
    inst = object.instructor
    return nil unless inst
    { name: inst.name, email: inst.email }
  end
end

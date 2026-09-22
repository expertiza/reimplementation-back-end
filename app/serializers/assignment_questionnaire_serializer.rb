class AssignmentQuestionnaireSerializer < ActiveModel::Serializer
  attributes :id, :questionnaire_id, :used_in_round, :questionnaire_weight,
             :notification_limit, :dropdown

  def questionnaire
    q = object.questionnaire
    return nil unless q
    { id: q.id, name: q.name, questionnaire_type: q.questionnaire_type }
  end

  attribute :questionnaire
end

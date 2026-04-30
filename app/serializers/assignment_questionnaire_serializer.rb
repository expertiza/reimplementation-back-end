class AssignmentQuestionnaireSerializer < ActiveModel::Serializer
  attributes :id, :questionnaire_id, :used_in_round, :questionnaire_weight, :notification_limit

  belongs_to :questionnaire
end

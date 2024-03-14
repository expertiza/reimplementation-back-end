class ResponseSerializer < ActiveModel::Serializer
  attributes :id, :map_id, :additional_comment, :is_submitted, :created_at, :updated_at, :version_num, :round, :visibility
  has_one :response_map
  has_many :scores

  class ResponseMapSerializer < ActiveModel::Serializer
    attributes :id, :reviewed_object_id, :reviewer_id, :reviewee_id, :type, :calibrate_to, :team_reviewing_enabled
    # attribute :title
    # def title
    #   if object.response_map.present? && object.response_map.get_title.present?
    #     object.response_map.get_title
    #   end
    # end
  end
  class ScoreSerializer < ActiveModel::Serializer
    attributes :id, :question_id, :response_id, :answer, :comments, :created_at, :updated_at
    has_one :question
    class QuestionSerializer < ActiveModel::Serializer
      attributes :id, :txt, :question_type, :weight
    end
  end

end

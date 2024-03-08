require 'response_service'
class ResponseDto
  attr_accessor :header, :next_action, :response, :map, :contributor, :return, :modified_object, :feedback, :assignment,
                :participant, :review_questions, :min, :max, :title, :survey_parent, :dropdown_or_scale, :questionnaire,
                :current_round, :locked
end


class QuizQuestionnaire < Questionnaire

  def taken_by_anyone?
    !ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap').empty?
  end

  def taken_by?(participant)
    !ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap', reviewer_id: participant.id).empty?
  end

end
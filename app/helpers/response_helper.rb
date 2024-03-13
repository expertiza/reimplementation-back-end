class ResponseHandler
  attr_reader :response, :res_helper, :errors
  def initialize(response)
    @res_helper = ResponseHelper.new
    @response = response
    @errors = []
  end

  def accept_content(params, action)
    if action == 'create'
      map_id = params[:map_id]
    else
      map_id = @response.response_map.id
    end
    @response.response_map = ResponseMap.find(map_id)
    if @response.response_map.nil?
      errors.push("Not found response map")
    else
      @response.round = @response.round || params[:response][:round]
      @response.additional_comment = params[:response][:comments] || @response.additional_comment
      @response.is_submitted = params[:response][:is_submitted] || @response.is_submitted
      @response.version_num = params[:response][:version_num] || @response.version_num
    end
  end

  def set_content(params, action)
    @response.response_map = ResponseMap.find(@response.map_id)
    if @response.response_map.nil?
      @errors.push(' Not found response map')
    else
      @response
    end
  end

end
class ResponseHelper
  include Scoring

  # sorts the questions passed by sequence number in ascending order
  def sort_questions(questions)
    questions.sort_by(&:seq)
  end
  # checks if the questionnaire is nil and opens drop down or rating accordingly
  def set_dropdown_or_scale(response)
    # todo: create a dropdown column to AssignmentQuestionnaire
    # use_dropdown = AssignmentQuestionnaire.where(assignment_id: response_dto.assignment.try(:id),
    #                                              questionnaire_id: response_dto.questionnaire.try(:id))
    #                                       .first.try(:dropdown)
    use_dropdown= true
    dropdown_or_scale = (use_dropdown ? 'dropdown' : 'scale')
    return dropdown_or_scale
  end

  # This method is called within set_content and when the new_response flag is set to true
  # Depending on what type of response map corresponds to this response, the method gets the reference to the proper questionnaire
  # This is called after assign_instance_vars in the new method
  def questionnaire_from_response_map(response)
    response_map = response.response_map
    case response_map.type
    when 'ReviewResponseMap', 'SelfReviewResponseMap'
      reviewees_topic = SignedUpTeam.topic_id_by_team_id(response_map.reviewee_id)
      current_round = response_map.assignment.number_of_current_round(reviewees_topic)
      questionnaire = response_map.questionnaire(response.round, reviewees_topic)
    when
    'MetareviewResponseMap',
      'TeammateReviewResponseMap',
      'FeedbackResponseMap',
      'CourseSurveyResponseMap',
      'AssignmentSurveyResponseMap',
      'GlobalSurveyResponseMap',
      'BookmarkRatingResponseMap'
      if response_map.assignment.duty_based_assignment?
        # E2147 : gets questionnaire of a particular duty in that assignment rather than generic questionnaire
        questionnaire = response_map.questionnaire_by_duty(response_map.reviewee.duty_id)
      else
        questionnaire = response_map.questionnaire
      end
    end
  end


  # This method is called within set_content when the new_response flag is set to False
  # This method gets the questionnaire directly from the response object since it is available.
  def questionnaire_from_response(response)
    # if user is not filling a new rubric, the response_dtoresponse object should be available.
    # we can find the questionnaire from the question_id in answers
    answer = response.scores.first
    questionnaire = response.questionnaire_by_answer(answer)
  end
  def score(params)
    Class.new.extend(Scoring).assessment_score(params)
  end
  def questionnaire_by_answer(answer)
    if answer.nil?
      # there is small possibility that the answers is empty: when the questionnaire only have 1 question and it is a upload file question
      # the reason is that for this question type, there is no answer record, and this question is handled by a different form
      map = ResponseMap.find(map_id)
      # E-1973 either get the assignment from the participant or the map itself
      assignment = if map.is_a? ReviewResponseMap
                     map.assignment
                   else
                     Participant.find(map.reviewer_id).assignment
                   end
      questionnaire = Questionnaire.find(assignment.review_questionnaire_id)
    else # for all the cases except the case that  file submission is the only question in the rubric.
      questionnaire = Question.find(answer.question_id).questionnaire
    end
    questionnaire
  end
  def notify_instructor_on_difference(response)
    response_map = response.map
    reviewer = AssignmentParticipant.includes(:user, :assignment).where("id=?", response_map.reviewer_id).first
    reviewee = AssignmentParticipant.includes(:user, :assignment).where("id=?", response_map.reviewee_id).first
    assignment = reviewee.assignment
    instructor = User.find(assignment.id)
    # todo
    # To simplify the process and decouple it from other classes, retrieving all necessary information for emailing in this class.
    Mailer.notify_grade_conflict_message(
      to: instructor.email,
      subject: 'Expertiza Notification: A review score is outside the acceptable range',
      body: {
        reviewer_name: reviewer.user.full_name,
        type: 'review',
        reviewee_name: reviewee.user.full_name,
        new_score: aggregate_questionnaire_score(response).to_f / maximum_score(response),
        assignment: assignment,
        conflicting_response_url: 'https://expertiza.ncsu.edu/response/view?id=' + response.id.to_s,
        summary_url: 'https://expertiza.ncsu.edu/grades/view_team?id=' + response_map.reviewee_id.to_s,
        assignment_edit_url: 'https://expertiza.ncsu.edu/assignments/' + assignment.id.to_s + '/edit'
      }
    ).deliver_now
  end
  def aggregate_questionnaire_score(response)
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    response.scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    sum
  end
  # Returns the maximum possible score for this response
  def maximum_score(response)
    # only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    total_weight = 0
    response.scores.each do |s|
      question = Question.find(s.question_id)
      total_weight += question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    questionnaire = if scores.empty?
                      questionnaire_by_answer(nil)
                    else
                      questionnaire_by_answer(scores.first)
                    end
    total_weight * questionnaire.max_question_score
  end
  # compare the current response score with other scores on the same artifact, and test if the difference
  # is significant enough to notify instructor.
  # Precondition: the response object is associated with a ReviewResponseMap
  ### "map_class.assessments_for" method need to be refactored
  def significant_difference?(response)
    map = response.map
    map_class = map.class
    existing_responses = map_class.assessments_for(map.reviewee)
    average_score_on_same_artifact_from_others, count = Response.avg_scores_and_count_for_prev_reviews(existing_responses, self)
    # if this response is the first on this artifact, there's no grade conflict
    return false if count.zero?

    # This score has already skipped the unfilled scorable question(s)
    score = response.aggregate_questionnaire_score.to_f / maximum_score
    questionnaire = response.questionnaire_by_answer(scores.first)
    assignment = map.assignment
    assignment_questionnaire = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
    # notification_limit can be specified on 'Rubrics' tab on assignment edit page.
    allowed_difference_percentage = assignment_questionnaire.notification_limit.to_f
    # the range of average_score_on_same_artifact_from_others and score is [0,1]
    # the range of allowed_difference_percentage is [0, 100]
    (average_score_on_same_artifact_from_others - score).abs * 100 > allowed_difference_percentage
  end
  # only two types of responses more should be added
  def notify_peer_review_ready (partial = 'new_submission', map_id)

    defn = {}
    defn[:body] = {}
    defn[:body][:partial_name] = partial
    response_map = ResponseMap.find map_id
    participant = Participant.find(response_map.reviewer_id)
    # parent is used as a common variable name for either an assignment or course depending on what the questionnaire is associated with
    parent = if response_map.survey?
               response_map.survey_parent
             else
               Assignment.find(participant.parent_id)
             end
    defn[:subject] = 'A new submission is available for ' + parent.name
    response_map.email(defn, participant, parent)
    defn[:body][:type] = 'Peer Review'
    AssignmentTeam.find(reviewee_id).users.each do |user|
      defn[:body][:obj_name] = assignment.name
      defn[:body][:first_name] = User.find(user.id).fullname
      defn[:to] = User.find(user.id).email
      Mailer.sync_message(defn).deliver_now
    end
  end

  # This method initialize answers for the questions in the response
  # Iterates over each questions and create corresponding answer for that
  def init_answers(response, questions)
    answers = []
    questions.each do |q|
      # it's unlikely that these answers exist, but in case the user refresh the browser some might have been inserted.
      answer = Answer.where(response_id: (response.id || 0), question_id: q.id).first
      if answer.nil?
        answer = Answer.new(response_id: (response.id || 0), question_id: q.id, answer: nil, comments: '')
      end
      answers.push(answer)
    end
    answers
  end
  # For each question in the list, starting with the first one, you update the comment and score
  def create_answers(response_id, answers)
    answers.each do |v|
      score = Answer.where(response_id: response_id, question_id: v[:question_id]).first
      score ||= Answer.create(response_id: response_id, question_id: v[:question_id], answer: v[:answer], comments: v[:comments])
      score.update_attribute('answer', v[:answer])
      score.update_attribute('comments', v[:comments])
    end
  end
  def question_with_answers(questions, response)
    questions_with_answers = []
    questions.each do |question|
      answer = Answer.where("response_id = ? and question_id = ?", response.id, question.id)
      if answer.nil?
        answer = Answer.new
        answer.question_id = question.id
        answer.response_id = response.id
      end
      question_with_answer = {
        question => question,
        answer => answer
      }
      questions_with_answers.push(question_with_answer)
    end
    questions_with_answers
  end
  def get_questions(response)
    #todo
    #questionnaire = questionnaire_from_response_map(response)
    questionnaire = Questionnaire.find(1)
    questionnaire.questions
    # review_questions = sort_questions(questionnaire.questions)
    # question_with_answers(review_questions, response)
  end
  def get_answers(response, questions)
    answers = []
    questions = sort_questions(questions)
    questions.each do |question|
      answer = nil
      if response.id.present?
        answer = Answer.where("response_id = ? and question_id = ?", response.id, question.id)
      end
      if answer.nil?
        answer = Answer.new
        answer.question_id = question.id
        answers.push(answer)
      end
    end
    answers
  end

end
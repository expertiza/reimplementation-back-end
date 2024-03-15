class ResponseHandler
  attr_reader :response, :res_helper, :errors
  def initialize(response)
    @res_helper = ResponseHelper.new
    @response = response
    @errors = []
  end

  def validate(params, action)
    if action == 'create'
      map_id = params[:map_id]
    else
      map_id = self.response.response_map.id
    end
    response_map = ResponseMap.includes(:responses).find(map_id)
    if response_map.nil?
      self.errors.push("Not found response map")
      return
    end

    self.response.response_map = response_map
    self.response.round = self.response.round || params[:response][:round]
    self.response.additional_comment = params[:response][:comments] || self.response.additional_comment
    self.response.version_num = params[:response][:version_num] || self.response.version_num
    
    if action == 'create'
      existing_response = response_map.responses.where("round = ? and version_num = ?", self.response.round, self.response.version_num)
      if existing_response.present?
        self.errors.push("Already existed.")
        return
      end
    elsif action == 'update'
      if params[:response][:is_submitted].present?
        if self.response.is_submitted
          self.errors.push("Already submitted.")
          return
        end
      end
    end
    self.response.is_submitted = params[:response][:is_submitted] || self.response.is_submitted
  end

  def set_content(params, action)
    self.response.response_map = ResponseMap.find(self.response.map_id)
    if self.response.response_map.nil?
      self.errors.push(' Not found response map')
    else
      self.response
    end
    questions = self.res_helper.get_questions(self.response)
    self.response.scores = self.res_helper.get_answers(self.response, questions)
    self.response
  end

end
class ResponseHelper

  # sorts the questions passed by sequence number in ascending order
  def sort_questions(questions)
    questions.sort_by(&:seq)
  end
  def get_questionnaire(response)
    quesionnaire = AssignmentQuestionnaire.find(response.response_map.assignment_questionnaire_id).questionnaire
  end
  # Returns the maximum possible score for this response
  def maximum_score(response)
    # only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    total_weight = 0
    response.scores.each do |s|
      question = Question.find(s.question_id)
      total_weight += question.weight
    end
    questionnaire = get_questionnaire(response)
    total_weight * questionnaire.max_question_score
  end
  
  def notify_instructor_on_difference(response)
    response_map = response.response_map
    reviewer = AssignmentParticipant.includes(:user, :assignment).where("id=?", response_map.reviewer_id).first
    reviewee = AssignmentParticipant.includes(:user, :assignment).where("id=?", response_map.reviewee_id).first
    assignment = reviewee.assignment
    instructor = User.find(assignment.id)
    # todo
    # To simplify the process and decouple it from other classes, retrieving all necessary information for emailing in this class.
    email = EmailObject.new(
      to: instructor.email,
      from: 'expertiza.mailer@gmail.com',
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
      }.to_s
    )
    Mailer.send_email(email)
  end
  
  def aggregate_questionnaire_score(response)
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    response.scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      #  todo
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
      #sum += s.answer * question.weight
    end
    sum
  end

  # updated email method name to notify_peer_review_ready, as the previous method name wasn't appropriate name.
  # only two types of responses more should be added
  def notify_peer_review_ready(map_id)

    email = EmailObject.new
    body = {}
    body += partial
    response_map = ResponseMap.find map_id
    participant = Participant.find(response_map.reviewer_id)
    # parent is used as a common variable name for either an assignment or course depending on what the questionnaire is associated with
    parent = if response_map.survey?
               response_map.survey_parent
             else
               Assignment.find(participant.parent_id)
             end
    email.subject = 'A new submission is available for ' + parent.name
    
    body += 'Peer Review\n'
    AssignmentTeam.find(reviewee_id).users.each do |user|
      email.body = body + '\n' + assignment.name + '\n'
      email.body += User.find(user.id).fullname
      email.to = User.find(user.id).email
      Mailer.send_email(email).deliver_now
    end
  end

  # For each question in the list, starting with the first one, you update the comment and score
  def create_update_answers(response, answers)
    answers.each do |v|
      unless v[:question_id].present?
        raise StandardError.new("Question Id required.")
      end
      score = Answer.where(response_id: response.id, question_id: v[:question_id]).first
      score ||= Answer.create(response_id: response.id, question_id: v[:question_id], answer: v[:answer], comments: v[:comments])
      score.update_attribute('answer', v[:answer])
      score.update_attribute('comments', v[:comments])
    end
  end
  def get_questions(response)
    questionnaire = aggregate_questionnaire_score(response)
    questionnaire.questions
  end
  def get_answers(response, questions)
    answers = []
    questions = sort_questions(questions)
    questions.each do |question|
      answer = nil
      if response.id.present?
        answer = Answer.where("response_id = ? and question_id = ?", response.id, question.id).first
      end
      if answer.nil?
        answer = Answer.new
        answer.question_id = question.id
        
      end
      answers.push(answer)
    end
    answers
  end
  def response_lock_action(map_id, locked)
    erro_msg = 'Another user is modifying this response or has modified this response. Try again later.'
  end
end
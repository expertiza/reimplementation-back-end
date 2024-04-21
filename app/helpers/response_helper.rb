module ResponseHelper
  # sorts the questions passed by sequence number in ascending order
  def sort_questions(questions)
    questions.sort_by(&:seq)
  end

  # Newly implemented method based on questionnaire_from_response_map, not yet tested.
  # Retrieves the corresponding questionnaire for a given response based on the response map type.
  # It determines the appropriate questionnaire by the type of response map and the current review round.
  def get_questionnaire(response)
    questionnaire = Questionnaire.find(1)
    # reviewees_topic_id = SignedUpTeam.topic_id_by_team_id(response.response_map.contributor.id)
    # current_round = assignment.number_of_current_round(reviewees_topic_id)
    # questionnaire = nil
    # response.response_map.type =~ /(.+)ResponseMap$/
    # questionnaire_type = $1 + "Questionnaire"
    # assignment = Assignment.includes(assignment_questionnaires: :questionnaire).where("id = ?", reviewees_topic_id)
    # assignment_questionnaires = assignment.assignment_questionnaires.joins(:questionnaire).distinct
    # if(assignment_questionnaires.count == 1)
    #   return assignment_questionnaires[0].questionnaire
    # else
    #   assignment_questionnaires.each do |aq|
    #     if aq.questionnaire.type == questionnaire_type && aq.used_in_round == current_round && aq.topic_id == reviewees_topic_id
    #       questionnaire = aq.questionnaire
    #     end
    #   end
    # end
  end

  # Calculates the maximum possible score for a given response.
  # Considers only scorable questions where the answer is not nil.
  def maximum_score(response)
    total_weight = 0
    response.scores.each do |score|
      question = Question.find(score.question_id)
      total_weight += question.weight unless score.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    questionnaire = get_questionnaire(response)
    total_weight * questionnaire.max_question_score
  end

  # Creates and sends a notification email to the instructor after a review is submitted,
  def notify_instructor_on_difference(response)
    response_map = response.response_map
    reviewer = AssignmentParticipant.includes(:user, :assignment).where('id=?', response_map.reviewer_id).first
    reviewee = AssignmentParticipant.includes(:user, :assignment).where('id=?', response_map.reviewee_id).first
    assignment = reviewee.assignment
    instructor = User.find(assignment.id)
    email = EmailObject.new(
      to: instructor.email,
      from: 'expertiza.mailer@gmail.com',
      subject: 'Expertiza Notification: A review score is outside the acceptable range',
      body: {
        reviewer_name: reviewer.user.full_name,
        type: 'review',
        reviewee_name: reviewee.user.full_name,
        new_score: aggregate_questionnaire_score(response).to_f / maximum_score(response),
        assignment:,
        conflicting_response_url: 'https://expertiza.ncsu.edu/response/view?id=' + response.id.to_s,
        summary_url: 'https://expertiza.ncsu.edu/grades/view_team?id=' + response_map.reviewee_id.to_s,
        assignment_edit_url: 'https://expertiza.ncsu.edu/assignments/' + assignment.id.to_s + '/edit'
      }.to_s
    )
    Mailer.send_email(email)
  end

  # Calculates the total score awarded for a review.
  def aggregate_questionnaire_score(response)
    sum = 0
    response.scores.each do |score|
      question = Question.find(score.question_id)
      sum += score.answer * question.weight unless score.answer.nil? || !question.is_a?(ScoredQuestion)
      sum += score.answer * question.weight
    end
    sum
  end

  # Renamed from the previous method name for clarity. Notifies team members via email
  # when a new submission version is available for review.
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

  # Creates answers based on the provided parameters from a reviewer.
  def create_answers(response, answers)
    Answer.transaction do
      answers.each do |answer|
        raise StandardError, 'Question Id required.' unless answer[:question_id].present?
  
        # Check if the answer already exists
        existing_answer = Answer.find_by(response_id: response.id, question_id: answer[:question_id])
        
        # Only create a new answer if it doesn't exist
        unless existing_answer
          Answer.create!(
            response_id: response.id,
            question_id: answer[:question_id],
            answer: answer[:answer],
            comments: answer[:comments]
          )
        end
      end
    end
  end

# Updates answers based on the provided parameters from a reviewer.
  def update_answers(response, answers)
    Answer.transaction do
      answers.each do |answer|
        raise StandardError, 'Question Id required.' unless answer[:question_id].present?
  
        # Find the existing answer
        existing_answer = Answer.find_by(response_id: response.id, question_id: answer[:question_id])
  
        # Update it if it exists
        if existing_answer
          existing_answer.update!(
            answer: answer[:answer],
            comments: answer[:comments]
          )
        else
          # Log or handle the case where an expected existing answer is not found
          Rails.logger.error("Expected to find an answer to update but did not for response_id: #{response.id}, question_id: #{answer[:question_id]}")
        end
      end
    end
  end
  




  # Retrieves the questionnaire associated with a given response.
  # This method determines the relevant questionnaire by examining the response's type and related information.
  def get_items(response)
    questionnaire = get_questionnaire(response)
    questionnaire.questions
  end

  # Generates answer objects for the 'scores' attribute of the response model, based on the response to a request.
  # This method organizes answers according to the questions sorted by their sequence numbers.
  def get_answers(response, questions)
    answers = []
    questions = sort_questions(questions)
    questions.each do |question|
      answer = nil
      if response.id.present?
        answer = Answer.where('response_id = ? and question_id = ?', response.id, question.id).first
      end
      if answer.nil?
        answer = Answer.new
        answer.question_id = question.id

      end
      answers.push(answer)
    end
    answers
  end
  
  # This method delete the answer objects of the response model before deleting the response model.
  def delete_answers?(response)
    items = get_items(response)
    answers = get_answers(response, items)
    count = answers.length
    answers.each do |answer|
      answer.destroy!
      count = count - 1
    end
    count == 0
  end

  # To be executed if the response is currently locked and cannot be edited.
  # This action handles scenarios where a response is being modified by another user or has recently been modified,
  # indicating that the user should attempt the operation again later.
  def response_lock_action(_map_id, _locked)
    erro_msg = 'Another user is modifying this response or has modified this response. Try again later.'
  end
end

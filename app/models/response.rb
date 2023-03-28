class Response < ApplicationRecord
  include ScorableMixin
  include MailMixin
  include ReviewCommentMixin

  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  # Get a collection of all comments across all rounds of a review
  # as well as a count of the total number of comments. Returns the
  # above information both for totals and in a list per-round.
  def self.get_all_review_comments(assignment_id, reviewer_id)
    comments = ''
    counter = 0
    @comments_in_round = []
    @counter_in_round = []
    assignment = Assignment.find(assignment_id)
    question_ids = Question.get_all_questions_with_comments_available(assignment_id)

    # Since reviews can have multiple rounds we need to iterate over all of them
    # to build our response.
    ReviewResponseMap.where(reviewed_object_id: assignment_id, reviewer_id: reviewer_id).find_each do |response_map|
      (1..assignment.num_review_rounds + 1).each do |round|
        @comments_in_round[round] = ''
        @counter_in_round[round] = 0
        last_response_in_current_round = response_map.response.select { |r| r.round == round }.last
        next if last_response_in_current_round.nil?

        last_response_in_current_round.scores.each do |answer|
          comments += answer.comments if question_ids.include? answer.question_id
          @comments_in_round[round] += (answer.comments ||= '')
        end
        additional_comment = last_response_in_current_round.additional_comment
        comments += additional_comment
        counter += 1
        @comments_in_round[round] += additional_comment
        @counter_in_round[round] += 1
      end
    end
    [comments, counter, @comments_in_round, @counter_in_round]
  end

  def display_as_html(prefix = nil, count = nil, _file_url = nil, show_tags = nil, current_user = nil)
    identifier = ''
    # The following three lines print out the type of rubric before displaying
    # feedback.  Currently this is only done if the rubric is Author Feedback.
    # It doesn't seem necessary to print out the rubric type in the case of
    # a ReviewResponseMap.
    identifier += '<h3>Feedback from author</h3>' if map.type.to_s == 'FeedbackResponseMap'
    if prefix # has prefix means view_score page in instructor end
      self_id = prefix + '_' + id.to_s
      code = construct_instructor_html identifier, self_id, count
    else # in student end
      self_id = id.to_s
      code = construct_student_html identifier, self_id, count
    end
    code = construct_review_response code, self_id, show_tags, current_user
    code.html_safe
  end

  def self.prev_reviews_count(existing_responses, current_response)
    count = 0
    existing_responses.each do |existing_response|
      unless existing_response.id == current_response.id # the current_response is also in existing_responses array
        count += 1
      end
    end
    count
  end

  def self.prev_reviews_avg_scores(existing_responses, current_response)
    scores_assigned = []
    existing_responses.each do |existing_response|
      unless existing_response.id == current_response.id # the current_response is also in existing_responses array
        scores_assigned << existing_response.aggregate_questionnaire_score.to_f / existing_response.maximum_score
      end
    end
    scores_assigned.sum / scores_assigned.size.to_f
  end

  # Computes the total score awarded for a review
  def aggregate_questionnaire_score
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    sum
  end

  def notify_instructor_on_difference
    response_map = map
    reviewer_participant_id = response_map.reviewer_id
    reviewer_participant = AssignmentParticipant.find(reviewer_participant_id)
    reviewer_name = User.find(reviewer_participant.user_id).fullname
    reviewee_team = AssignmentTeam.find(response_map.reviewee_id)
    reviewee_participant = reviewee_team.participants.first # for team assignment, use the first member's name.
    reviewee_name = User.find(reviewee_participant.user_id).fullname
    assignment = Assignment.find(reviewer_participant.parent_id)
    Mailer.notify_grade_conflict_message(
      to: assignment.instructor.email,
      subject: 'Expertiza Notification: A review score is outside the acceptable range',
      body: {
        reviewer_name: reviewer_name,
        type: 'review',
        reviewee_name: reviewee_name,
        new_score: aggregate_questionnaire_score.to_f / maximum_score,
        assignment: assignment,
        conflicting_response_url: 'https://expertiza.ncsu.edu/response/view?id=' + response_id.to_s,
        summary_url: 'https://expertiza.ncsu.edu/grades/view_team?id=' + reviewee_participant.id.to_s,
        assignment_edit_url: 'https://expertiza.ncsu.edu/assignments/' + assignment.id.to_s + '/edit'
      }
    ).deliver_now
  end

  private

  def construct_instructor_html(identifier, self_id, count)
    identifier += '<h4><B>Review ' + count.to_s + '</B></h4>'
    identifier += '<B>Reviewer: </B>' + map.reviewer.fullname + ' (' + map.reviewer.name + ')'
    identifier + '&nbsp;&nbsp;&nbsp;<a href="#" name= "review_' + self_id + 'Link" onClick="toggleElement(' \
           "'review_" + self_id + "','review'" + ');return false;">hide review</a><BR/>'
  end

  def construct_student_html(identifier, self_id, count)
    identifier += '<table width="100%">' \
             '<tr>' \
             '<td align="left" width="70%"><b>Review ' + count.to_s + '</b>&nbsp;&nbsp;&nbsp;' \
             '<a href="#" name= "review_' + self_id + 'Link" onClick="toggleElement(' + "'review_" + self_id + "','review'" + ');return false;">hide review</a>' \
             '</td>' \
             '<td align="left"><b>Last Reviewed:</b>' \
             "<span>#{(updated_at.nil? ? 'Not available' : updated_at.strftime('%A %B %d %Y, %I:%M%p'))}</span></td>" \
             '</tr></table>'
    identifier
  end

  def construct_review_response(code, self_id, show_tags = nil, current_user = nil)
    code += '<table id="review_' + self_id + '" class="table table-bordered">'
    answers = Answer.where(response_id: response_id)
    unless answers.empty?
      questionnaire = questionnaire_by_answer(answers.first)
      questionnaire_max = questionnaire.max_question_score
      questions = questionnaire.questions.sort_by(&:seq)
      # get the tag settings this questionnaire
      tag_prompt_deployments = show_tags ? TagPromptDeployment.where(questionnaire_id: questionnaire.id, assignment_id: map.assignment.id) : nil
      code = add_table_rows questionnaire_max, questions, answers, code, tag_prompt_deployments, current_user
    end
    comment = if additional_comment.nil?
                ''
              else
                additional_comment.gsub('^p', '').gsub(/\n/, '<BR/>')
              end
    code += '<tr><td><b>Additional Comment: </b>' + comment + '</td></tr>'
    code += '</table>'
    code
  end
end

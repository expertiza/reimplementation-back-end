module GradesHelper
  include PenaltyHelper

  # This function calculates all the penalties
  def penalties(assignment_id)
    @all_penalties = {}
    @assignment = Assignment.find(assignment_id)
    calculate_for_participants = true unless @assignment.is_penalty_calculated
    Participant.where(parent_id: assignment_id).each do |participant|
      penalties = calculate_penalty(participant.id)
      @total_penalty = 0

      unless penalties[:submission].zero? || penalties[:review].zero? || penalties[:meta_review].zero?

        @total_penalty = (penalties[:submission] + penalties[:review] + penalties[:meta_review])
        l_policy = LatePolicy.find(@assignment.late_policy_id)
        @total_penalty = l_policy.max_penalty if @total_penalty > l_policy.max_penalty
        attributes(@participant) if calculate_for_participants
      end
      assign_all_penalties(participant, penalties)
    end
    @assignment[:is_penalty_calculated] = true unless @assignment.is_penalty_calculated
  end


  # Helper to retrieve participant and related assignment data
def fetch_participant_and_assignment
  @participant = AssignmentParticipant.find(params[:id])
  @assignment = @participant.assignment
end

# Helper to retrieve questionnaires and questions
def fetch_questionnaires_and_questions
  questionnaires = @assignment.questionnaires
  @questions = retrieve_questions(questionnaires, @assignment.id)
end

# Helper to fetch participant scores
def fetch_participant_scores
  @pscore = participant_scores(@participant, @questions)
end

# Helper to calculate penalties
def fetch_penalties
  penalties(@assignment.id)
end

# Helper to summarize reviews by reviewee
def fetch_feedback_summary
  summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
  sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(@questions, @assignment, @team_id, summary_ws_url, session)
  @summary = sum.summary
  @avg_scores_by_round = sum.avg_scores_by_round
  @avg_scores_by_criterion = sum.avg_scores_by_criterion
end

def process_questionare_for_team(assignment, team_id)
  vmlist = []

  counter_for_same_rubric = 0
  if @assignment.vary_by_topic?
    topic_id = SignedUpTeam.topic_id_by_team_id(@team_id)
    topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: @assignment.id, topic_id: topic_id).first.questionnaire
    @vmlist << populate_view_model(topic_specific_questionnaire)
  end

  questionnaires.each do |questionnaire|
    @round = nil

    # Guard clause to skip questionnaires that have already been populated for topic specific reviewing
    if @assignment.vary_by_topic? && questionnaire.type == 'ReviewQuestionnaire'
      next # Assignments with topic specific rubrics cannot have multiple rounds of review
    end

    if @assignment.varying_rubrics_by_round? && questionnaire.type == 'ReviewQuestionnaire'
      questionnaires = AssignmentQuestionnaire.where(assignment_id: @assignment.id, questionnaire_id: questionnaire.id)
      if questionnaires.count > 1
        @round = questionnaires[counter_for_same_rubric].used_in_round
        counter_for_same_rubric += 1
      else
        @round = questionnaires[0].used_in_round
        counter_for_same_rubric = 0
      end
    end
    vmlist << populate_view_model(questionnaire)
  end
  return vmlist
end


# Copied from Expertiza code
def redirect_when_disallowed
  # For author feedback, participants need to be able to read feedback submitted by other teammates.
  # If response is anything but author feedback, only the person who wrote feedback should be able to see it.
  ## This following code was cloned from response_controller.

  # ACS Check if team count is more than 1 instead of checking if it is a team assignment
  if @participant.assignment.max_team_size > 1
    team = @participant.team
    unless team.nil? || (team.user? session[:user])
      flash[:error] = 'You are not on the team that wrote this feedback'
      redirect_to '/'
      return true
    end
  else
    reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: @participant.assignment.id).first
    return true unless current_user_id?(reviewer.try(:user_id))
  end
  false
end

end
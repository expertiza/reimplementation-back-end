module GradesHelper
  include PenaltyHelper

  # Calculates and applies penalties for participants of a given assignment.
  def penalties(assignment_id)
    @assignment = Assignment.find(assignment_id)
    calculate_for_participants = should_calculate_penalties?
  
    Participant.where(parent_id: assignment_id).each do |participant|
      penalties = calculate_penalty(participant.id)
      @total_penalty = calculate_total_penalty(penalties)
  
      if @total_penalty > 0
        @total_penalty = apply_max_penalty(@total_penalty)
        attributes(@participant) if calculate_for_participants
      end
  
      assign_all_penalties(participant, penalties)
    end
  
    mark_penalty_as_calculated unless @assignment.is_penalty_calculated
  end

  # Calculates and applies penalties for the current assignment.
  def update_penalties
    penalties(@assignment.id)
  end

  # Retrieves the name of the current user's role, if available.
  def current_role_name
    current_role.try :name
  end

  # Retrieves questions from the given questionnaires for the specified assignment, considering the round if applicable.
  def retrieve_questions(questionnaires, assignment_id)
    questions = {}
    questionnaires.each do |questionnaire|
      round = AssignmentQuestionnaire.where(assignment_id: assignment_id, questionnaire_id: questionnaire.id).first.used_in_round
      questionnaire_symbol = if round.nil?
                               questionnaire.symbol
                             else
                               (questionnaire.symbol.to_s + round.to_s).to_sym
                             end
      questions[questionnaire_symbol] = questionnaire.questions
    end
    questions
  end

  # Retrieves the participant and their associated assignment data.
  def fetch_participant_and_assignment
    @participant = AssignmentParticipant.find(params[:id])
    @assignment = @participant.assignment
  end

  # Retrieves the questionnaires and their associated questions for the assignment.
  def fetch_questionnaires_and_questions
    questionnaires = @assignment.questionnaires
    @questions = retrieve_questions(questionnaires, @assignment.id)
  end

  # Fetches the scores for the participant based on the retrieved questions.
  def fetch_participant_scores
    @pscore = participant_scores(@participant, @questions)
  end


  # Summarizes the feedback received by the reviewee, including overall summary and average scores by round and criterion.
  def fetch_feedback_summary
    summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
    sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(@questions, @assignment, @team_id, summary_ws_url, session)
    @summary = sum.summary
    @avg_scores_by_round = sum.avg_scores_by_round
    @avg_scores_by_criterion = sum.avg_scores_by_criterion
  end

  # Processes questionnaires for a team, considering topic-specific and round-specific rubrics, and populates view models accordingly.
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

  # Redirects the user if they are not allowed to access the assignment, based on team or reviewer authorization.
  def redirect_when_disallowed
    if team_assignment?
      redirect_if_not_on_correct_team
    else
      redirect_if_not_authorized_reviewer
    end
    false
  end 

  # Populates the view model with questionnaire data, team members, reviews, and calculated metrics.
  def populate_view_model(questionnaire)
    vm = VmQuestionResponse.new(questionnaire, @assignment, @round)
    vmquestions = questionnaire.questions
    vm.add_questions(vmquestions)
    vm.add_team_members(@team)
    qn = AssignmentQuestionnaire.where(assignment_id: @assignment.id, used_in_round: 2).size >= 1
    vm.add_reviews(@participant, @team, @assignment.varying_rubrics_by_round?)
    vm.calculate_metrics
    vm
  end

  # Finds an assignment participant by ID, and handles the case where the participant is not found.
  def find_participant(participant_id)
    AssignmentParticipant.find(participant_id)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Assignment participant #{participant_id} not found"
    nil
  end
  
  # Finds an assignment participant by ID, and handles the case where the participant is not found.
  def find_assignment(assignment_id)
    Assignment.find(assignment_id)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Assignment participant #{assignment_id} not found"
    nil
  end

  private
  
  # Determines if penalties should be calculated based on the assignment's penalty status.
  def should_calculate_penalties?
    !@assignment.is_penalty_calculated
  end
  
  # Calculates the total penalty from submission, review, and meta-review penalties.
  def calculate_total_penalty(penalties)
    total = penalties[:submission] + penalties[:review] + penalties[:meta_review]
    total > 0 ? total : 0
  end
  
  # Applies the maximum penalty limit based on the assignment's late policy.
  def apply_max_penalty(total_penalty)
    late_policy = LatePolicy.find(@assignment.late_policy_id)
    total_penalty > late_policy.max_penalty ? late_policy.max_penalty : total_penalty
  end
  
  # Marks the assignment's penalty status as calculated.
  def mark_penalty_as_calculated
    @assignment.update(is_penalty_calculated: true)
  end

  def assign_all_penalties(participant, penalties)
    @all_penalties[participant.id] = {
      submission: penalties[:submission],
      review: penalties[:review],
      meta_review: penalties[:meta_review],
      total_penalty: @total_penalty
    }
  end

  # Checks if the assignment is a team assignment based on the maximum team size.
  def team_assignment?
    @participant.assignment.max_team_size > 1
  end
  
  # Redirects the user if they are not on the correct team that provided the feedback.
  def redirect_if_not_on_correct_team
    team = @participant.team
    if team.nil? || !team.user?(session[:user])
      flash[:error] = 'You are not on the team that wrote this feedback'
      redirect_to '/'
    end
  end
  
  # Redirects the user if they are not an authorized reviewer for the feedback.
  def redirect_if_not_authorized_reviewer
    reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: @participant.assignment.id).first
    return if current_user_id?(reviewer.try(:user_id))
  
    flash[:error] = 'You are not authorized to view this feedback'
    redirect_to '/'
  end


end
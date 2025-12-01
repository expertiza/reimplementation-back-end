module GradesHelper
  include PenaltyHelper

  # Calculates and applies penalties for participants of a given assignment.
  def penalties(assignment_id)
    assignment = Assignment.find(assignment_id)
    calculate_for_participants = should_calculate_penalties?(assignment)
  
    all_penalties = {} 

    Participant.where(assignment_id: assignment_id).each do |participant|
      penalties = calculate_penalty(participant.id)
      total_penalty = calculate_total_penalty(penalties)
  
      if total_penalty > 0
        total_penalty = apply_max_penalty(total_penalty)
        attributes(participant) if calculate_for_participants
      end
  
      all_penalties = assign_all_penalties(participant, penalties)
    end
  
    mark_penalty_as_calculated(assignment) unless assignment.is_penalty_calculated
    return all_penalties
  end

  # Calculates and applies penalties for the current assignment.
  def update_penalties(assignment)
    penalties(assignment.id)
  end

  # Retrieves the name of the current user's role, if available.
  def current_role_name
    current_role.try :name
  end

  # Retrieves items from the given questionnaires for the specified assignment, considering the round if applicable.
  def retrieve_items(questionnaires, assignment_id)
    items = {}
    questionnaires.each do |questionnaire|
      round = AssignmentQuestionnaire.where(assignment_id: assignment_id, questionnaire_id: questionnaire.id).first.used_in_round
      #can accommodate other types of questionnaires too such as TeammateReviewQuestionnaire, AuthorFeedbackQuestionnaire
      questionnaire_symbol = if round.nil?
                               questionnaire.display_type
                             else
                               (questionnaire.display_type.to_s + '-Round-' + round.to_s).to_sym
                             end
      # questionnaire_symbol = questionnaire.id
      items[questionnaire_symbol] = questionnaire.items
    end
    items  
  end

  # Retrieves the participant and their associated assignment data.
  def fetch_participant_and_assignment(id)
    @participant = AssignmentParticipant.find(id)
    @assignment = @participant.assignment
  end

  # Retrieves the questionnaires and their associated items for the assignment.
  def fetch_questionnaires_and_items(assignment)
    questionnaires = assignment.questionnaires
    items = retrieve_items(questionnaires, assignment.id)
    return items
  end

  # Fetches the scores for the participant based on the retrieved items.
  def fetch_participant_scores(participant, items)
    pscore = Response.participant_scores(participant, items)
    return pscore
  end


  # Summarizes the feedback received by the reviewee, including overall summary and average scores by round and criterion.
  def fetch_feedback_summary
    summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
    sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(@items, @assignment, @team_id, summary_ws_url, session)
    @summary = sum.summary
    @avg_scores_by_round = sum.avg_scores_by_round
    @avg_scores_by_criterion = sum.avg_scores_by_criterion
  end

  # Processes questionnaires for a team, considering topic-specific and round-specific rubrics, and populates view models accordingly.
  def process_questionare_for_team(assignment, team_id, questionnaires, team, participant)
    vmlist = []

    counter_for_same_rubric = 0
    # if @assignment.vary_by_topic?
    #   topic_id = SignedUpTeam.topic_id_by_team_id(@team_id)
    #   topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: @assignment.id, topic_id: topic_id).first.questionnaire
    #   @vmlist << populate_view_model(topic_specific_questionnaire)
    # end

    questionnaires.each do |questionnaire|
      round = nil

      # Guard clause to skip questionnaires that have already been populated for topic specific reviewing
      # if @assignment.vary_by_topic? && questionnaire.type == 'ReviewQuestionnaire'
      #   next # Assignments with topic specific rubrics cannot have multiple rounds of review
      # end

      if assignment.varying_rubrics_by_round? && questionnaire.questionnaire_type == 'ReviewQuestionnaire'
        questionnaires = AssignmentQuestionnaire.where(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
        if questionnaires.count > 1
          round = questionnaires[counter_for_same_rubric].used_in_round
          counter_for_same_rubric += 1
        else
          round = questionnaires[0].used_in_round
          counter_for_same_rubric = 0
        end
      end
      vmlist << populate_view_model(questionnaire, assignment, round, team, participant)
    end
    return vmlist
  end

  # Redirects the user if they are not allowed to access the assignment, based on team or reviewer authorization.
  def redirect_when_disallowed(participant)
    if is_team_assignment?(participant)
      redirect_if_not_on_correct_team(participant)
    else
      redirect_if_not_authorized_reviewer(participant)
    end
    false
  end 

  # Populates the view model with questionnaire data, team members, reviews, and calculated metrics.
  def populate_view_model(questionnaire, assignment, round, team, participant)
    vm = VmQuestionResponse.new(questionnaire, assignment, round)
    vmitems = questionnaire.items
    vm.add_items(vmitems)
    vm.add_team_members(team)
    qn = AssignmentQuestionnaire.where(assignment_id: assignment.id, used_in_round: 2).size >= 1
    vm.add_reviews(participant, team, assignment.varying_rubrics_by_round?)
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

  # Checks if the student has the necessary permissions and authorizations to proceed.
  def student_with_permissions?
    has_role?('Student') &&
      self_review_finished?(current_user.id) &&
      are_needed_authorizations_present?(current_user.id, 'reader', 'reviewer')
  end

  # Checks if the user is either a student viewing their own team or has Teaching Assistant privileges.
  def student_or_ta?
    student_viewing_own_team? || has_privileges_of?('Teaching Assistant')
  end

  # This method checks if the current user, who must have the 'Student' role, is viewing their own team.
  def student_viewing_own_team?
    return false unless has_role?('Student')
  
    participant = AssignmentParticipant.find_by(id: params[:id])
    participant && current_user_is_assignment_participant?(participant.assignment.id)
  end

  # Check if the self-review for the participant is finished based on assignment settings and submission status.
  def self_review_finished?(id)
    participant = Participant.find(id)
    assignment = participant.try(:assignment)
    self_review_enabled = assignment.try(:is_selfreview_enabled)
    not_submitted = ResponseMap.self_review_pending?(participant.try(:id))
    puts self_review_enabled
    if self_review_enabled
      !not_submitted
    else
      true
    end
  end


  # Methods associated with View methods:
  # Determines if the rubric changes by round and returns the corresponding items based on the criteria.
  def filter_questionnaires(assignment)
    questionnaires = assignment.questionnaires
    if assignment.varying_rubrics_by_round?
      retrieve_items(questionnaires, assignment.id)
    else
      items = {}
      questionnaires.each do |questionnaire|
        items[questionnaire.id.to_s.to_sym] = questionnaire.items
      end
      items
    end
  end

  
  # This method retrieves all items from relevant questionnaires associated with this assignment. 
  def list_items(assignment)
    return {} unless assignment&.questionnaires&.any?
    
    assignment.questionnaires.each_with_object({}) do |questionnaire, items|
      items[questionnaire.id.to_s] = questionnaire.items.to_a rescue []
    end
  rescue => e
    Rails.logger.error "Error in list_items: #{e.message}"
    {}
  end

  # Method associated with Update methods:
  # Displays an error message if the participant is not found.
  def handle_not_found
    render json: { error: 'Participant not found.' }, status: :not_found
  end

  # Checks if the participant's grade has changed compared to the new grade.
  def grade_changed?(participant, new_grade)
    return false if new_grade.nil?

    format('%.2f', params[:total_score]) != new_grade
  end

  # Generates a message based on whether the participant's grade is present or computed.
  def grade_message(participant)
    participant.grade.nil? ? "The computed score will be used for #{participant.user.name}." :
                             "A score of #{participant.grade}% has been saved for #{participant.user.name}."
  end


  # Methods associated with instructor_review: 
  # Finds or creates a reviewer for the given user and assignment, and sets a handle if it's a new record
  def find_or_create_reviewer(user_id, assignment_id)
    reviewer = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    reviewer.set_handle if reviewer.new_record?
    reviewer
  end

  # Finds or creates a review mapping between the reviewee and reviewer for the given assignment.
  def find_or_create_review_mapping(reviewee_id, reviewer_id, assignment_id)
    ReviewResponseMap.find_or_create_by(reviewee_id: reviewee_id, reviewer_id: reviewer_id, reviewed_object_id: assignment_id)
  end
  
  # Redirects to the appropriate review page based on whether the review mapping is new or existing.
  def redirect_to_review(review_mapping)
    if review_mapping.new_record?
      redirect_to controller: 'response', action: 'new', id: review_mapping.map_id, return: 'instructor'
    else
      review = Response.find_by(map_id: review_mapping.map_id)
      redirect_to controller: 'response', action: 'edit', id: review.id, return: 'instructor'
    end
  end

  private
  
  # Determines if penalties should be calculated based on the assignment's penalty status.
  def should_calculate_penalties?(assignment)
    !assignment.is_penalty_calculated
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
  def mark_penalty_as_calculated(assignment)
    assignment.update(is_penalty_calculated: true)
  end

  def assign_all_penalties(participant, penalties)
    all_penalties[participant.id] = {
      submission: penalties[:submission],
      review: penalties[:review],
      meta_review: penalties[:meta_review],
      total_penalty: @total_penalty
    }
    return all_penalties
  end

  # Checks if the assignment is a team assignment based on the maximum team size.
  def is_team_assignment?(participant)
    participant.assignment.max_team_size > 1
  end
  
  # Redirects the user if they are not on the correct team that provided the feedback.
  def redirect_if_not_on_correct_team(participant)
    team = participant.team
    puts team.attributes
    if team.nil? || !team.user?(session[:user])
      flash[:error] = 'You are not on the team that wrote this feedback'
      redirect_to '/'
    end
  end
  
  # Redirects the user if they are not an authorized reviewer for the feedback.
  def redirect_if_not_authorized_reviewer(participant)
    reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: participant.assignment.id).first
    return if current_user_id?(reviewer.try(:user_id))
  
    flash[:error] = 'You are not authorized to view this feedback'
    redirect_to '/'
  end

  # def get_penalty_from_helper(participant_id)
  #   get_penalty(participant_id)
  # end

end
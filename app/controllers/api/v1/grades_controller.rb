class Api::V1::GradesController < ApplicationController
  include GradesHelper

  # def action_allowed?
  #   permitted = case params[:action]
  #               when 'view_my_scores'
  #                 student_with_permissions?
  #               when 'view_team'
  #                 student_viewing_own_team? || has_privileges_of?('Teaching Assistant')
  #               else
  #                 has_privileges_of?('Teaching Assistant')
  #               end
  
  #   render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  # end

  ACTION_PERMISSIONS = {
    'view_my_scores' => :student_with_permissions?,
    'view_team' => :student_or_ta?
  }.freeze

  def action_allowed?
    permitted = check_permission(params[:action])
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end

  


  def view_grading_report
    get_data_for_heat_map(params[:id])
    fetch_penalties
    @show_reputation = false
  end
    


  def view_my_scores
    fetch_participant_and_assignment
    @team_id = TeamsUser.team_id(@participant.parent_id, @participant.user_id)
    return if redirect_when_disallowed

    fetch_questionnaires_and_questions
    fetch_participant_scores
    # get_data_for_heat_map()

    @topic_id = SignedUpTeam.topic_id(@participant.assignment.id, @participant.user_id)
    @stage = @participant.assignment.current_stage(@topic_id)
    fetch_penalties
    
    # prepare feedback summaries
    fetch_feedback_summary
  end




  def view_team
    fetch_participant_and_assignment
    @team = @participant.team
    @team_id = @team.id

    questionnaires = AssignmentQuestionnaire.where(assignment_id: @assignment.id, topic_id: nil).map(&:questionnaire)
    @questions = retrieve_questions(questionnaires, @assignment.id)
    @pscore = Response.participant_scores(@participant, @questions)
    @penalties = calculate_penalty(@participant.id)
    @vmlist = process_questionare_for_team(@assignment, @team_id)

    @current_role_name = current_role_name
  end



  def edit_participant_scores 
    @participant = find_participant(params[:id])
    return unless @participant # Exit early if participant not found
    @assignment = @participant.assignment
    @questions = list_questions(@assignment)
    @scores = Response.review_grades(@participant, @questions)
  end





  def list_questions(assignment)
    assignment.questionnaires.each_with_object({}) do |questionnaire, questions|
      questions[questionnaire.id.to_s] = questionnaire.questions
    end
  end





  def update_participant_grade
    participant = AssignmentParticipant.find_by(id: params[:id])
    return handle_not_found unless participant

    new_grade = params[:participant][:grade]
    if grade_changed?(participant, new_grade)
      participant.update(grade: new_grade)
      flash[:note] = grade_message(participant)
    end
    redirect_to action: 'edit', id: params[:id]
  end






  def update_team
    participant = AssignmentParticipant.find_by(id: params[:participant_id])
    return handle_not_found unless participant

    if participant.team.update(grade_for_submission: params[:grade_for_submission],
                               comment_for_submission: params[:comment_for_submission])
      flash[:success] = 'Grade and comment for submission successfully saved.'
    else
      flash[:error] = 'Error saving grade and comment.'
    end
    redirect_to controller: 'grades', action: 'view_team', id: params[:id]
  end






  def instructor_review
    participant = find_participant(params[:id])
    return unless participant # Exit early if participant not found
  
    reviewer = find_or_create_reviewer(session[:user].id, participant.assignment.id)
    review_mapping = find_or_create_review_mapping(participant.team.id, reviewer.id, participant.assignment.id)
  
    redirect_to_review(review_mapping)
  end
  



  private



# Helper methods for action_allowed?

  def check_permission(action)
    return has_privileges_of?('Teaching Assistant') unless ACTION_PERMISSIONS.key?(action)

    send(ACTION_PERMISSIONS[action])
  end

  def student_with_permissions?
    has_role?('Student') &&
      self_review_finished? &&
      are_needed_authorizations_present?(params[:id], 'reader', 'reviewer')
  end

  def student_or_ta?
    student_viewing_own_team? || has_privileges_of?('Teaching Assistant')
  end

  def student_viewing_own_team?
    return false unless has_role?('Student')
  
    participant = AssignmentParticipant.find_by(id: params[:id])
    participant && current_user_is_assignment_participant?(participant.assignment.id)
  end

  def self_review_finished?
    participant = Participant.find(params[:id])
    assignment = participant.try(:assignment)
    self_review_enabled = assignment.try(:is_selfreview_enabled)
    not_submitted = ResponseMap.self_review_pending?(participant.try(:id))
    if self_review_enabled
      !not_submitted
    else
      true
    end
  end


# Helper methods for the instructor_review

  def find_or_create_reviewer(user_id, assignment_id)
    reviewer = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    reviewer.set_handle if reviewer.new_record?
    reviewer
  end

  def find_or_create_review_mapping(reviewee_id, reviewer_id, assignment_id)
    ReviewResponseMap.find_or_create_by(reviewee_id: reviewee_id, reviewer_id: reviewer_id, reviewed_object_id: assignment_id)
  end
  
  def redirect_to_review(review_mapping)
    if review_mapping.new_record?
      redirect_to controller: 'response', action: 'new', id: review_mapping.map_id, return: 'instructor'
    else
      review = Response.find_by(map_id: review_mapping.map_id)
      redirect_to controller: 'response', action: 'edit', id: review.id, return: 'instructor'
    end
  end



# Helper methods for update

  def handle_not_found
    flash[:error] = 'Participant not found.'
  end

  def grade_changed?(participant, new_grade)
    return false if new_grade.nil?

    format('%.2f', params[:total_score]) != new_grade
  end

  def grade_message(participant)
    participant.grade.nil? ? "The computed score will be used for #{participant.user.name}." :
                             "A score of #{participant.grade}% has been saved for #{participant.user.name}."
  end

# These could go in a helper method

  def find_participant(participant_id)
    AssignmentParticipant.find(participant_id)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Assignment participant #{participant_id} not found"
    nil
  end
  

  def find_assignment(assignment_id)
    Assignment.find(assignment_id)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Assignment participant #{assignment_id} not found"
    nil
  end


  # Helper methods for views
  
  def filter_questionnaires(assignment)
    questionnaires = assignment.questionnaires
    if assignment.varying_rubrics_by_round?
      retrieve_questions(questionnaires, assignment.id)
    else
      questions = {}
      questionnaires.each do |questionnaire|
        questions[questionnaire.id.to_s.to_sym] = questionnaire.questions
      end
      questions
    end
  end

  def get_data_for_heat_map(assignment_id)
    # Finds the assignment
    @assignment = find_assignment(assignment_id)
    # Extracts the questionnaires
    @questions = filter_questionnaires(@assignment)
    @scores = Response.review_grades(@assignment, @questions)
    @review_score_count = @scores[:teams].length # After rejecting nil scores need original length to iterate over hash
    @averages = Response.extract_team_averages(@scores[:teams])
    @avg_of_avg = Response.average_team_scores(@averages)
  end




end



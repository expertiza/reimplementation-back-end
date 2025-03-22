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


  # Defines permissions for different actions based on user roles.
  # 'view_my_scores' is allowed for students with specific permissions.
  # 'view_team' is allowed for both students and TAs.
  # 'view_grading_report' is allowed TAs and higher roles. 
  ACTION_PERMISSIONS = {
    'view_my_scores' => :student_with_permissions?,
    'view_team' => :student_or_ta?
  }.freeze

<<<<<<< Updated upstream
  # Determines if the current user is allowed to perform the specified action.
  # Checks the permission using the action parameter and returns a JSON response.
  # If the action is permitted, the response status is :ok; otherwise, it is :forbidden.
  def action_allowed?
=======
  def action_allowed
>>>>>>> Stashed changes
    permitted = check_permission(params[:action])
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end

  # The view_grading_report offers instructors a comprehensive overview of all grades for an assignment.
  # It displays all participants and the reviews they have received.
  # Additionally, it provides a final score, which is the average of all reviews, and highlights the greatest
  # difference in scores among the reviews.
  def view_grading_report
    get_data_for_heat_map(params[:id])
    fetch_penalties
    @show_reputation = false
  end
    
  # The view_my_scores method provides participants with a detailed overview of their performance in an assignment.
  # It retrieves and their questions and calculated scores and prepares feedback summaries.
  # Additionally, it applies any penalties and determines the current stage of the assignment.
  # This method ensures participants have a comprehensive understanding of their scores and feedback
  def view_my_scores
    fetch_participant_and_assignment
    @team_id = TeamsUser.team_id(@participant.parent_id, @participant.user_id)
    return if redirect_when_disallowed

    fetch_questionnaires_and_questions
    fetch_participant_scores
  
    @topic_id = SignedUpTeam.topic_id(@participant.assignment.id, @participant.user_id)
    @stage = @participant.assignment.current_stage(@topic_id)
    fetch_penalties
    
    # prepare feedback summaries
    fetch_feedback_summary
  end

  # The view_team method provides an alternative view for participants, focusing on team performance.
  # It retrieves the participant, assignment, and team information, and calculated scores and penalties.
  # Additionally, it prepares the necessary data for displaying team-related information.
  # This method ensures participants have a clear understanding of their team's performance and any associated penalties.
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


  # Prepares the necessary information for editing grade details, including the participant, questions, scores, and assignment.
  # The participant refers to the student whose grade is being modified.
  # The assignment is the specific task for which the participant's grade is being reviewed.
  # The questions are the rubric items or criteria associated with the assignment.
  # The scores represent the combined scoring information for both the participant and their team, required for frontend display.
  def edit_participant_scores 
    @participant = find_participant(params[:id])
    return unless @participant # Exit early if participant not found
    @assignment = @participant.assignment
    @questions = list_questions(@assignment)
    @scores = Response.review_grades(@participant, @questions)
  end

  
  # Update method for the grade associated with a participant.
  # Allows an instructor to upgrade a participant's grade and provide feedback on their assignment submission.
  # The updated participant information is saved for future scoring evaluations.
  # If saving the participant fails, a flash error populates.
  # Finally, the instructor is redirected to the edit pages.
  def update_participant_grade
    participant = AssignmentParticipant.find_by(id: params[:id])
    return handle_not_found unless participant

    new_grade = params[:participant][:grade]
    if grade_changed?(participant, new_grade)
      participant.update(grade: new_grade)
      flash[:note] = grade_message(participant)
    else
      flash[:error] = 'Error updating participant grade.'
    end
    # Redirect to the edit action for the participant.
    redirect_to action: 'edit', id: params[:id]
  end

  # Update the grade and comment for a participant's submission.
  # Save the updated information for future evaluations.
  # Handle errors by returning a bad_request response.
  # Provide feedback to the user about the operation's success or failure.
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

  # Determines the appropriate controller action for an instructor's review based on the current state.
  # This method checks if a review mapping exists for the participant. If it does, the instructor is directed to edit the existing review.
  # If no review mapping exists, the instructor is directed to create a new review.
  # The Response controller handles both creating and editing reviews through its response#new and response#edit actions.
  # This method ensures the correct action is taken by checking the existence of a review mapping and utilizing the new_record functionality.
  def instructor_review
    participant = find_participant(params[:id])
    return unless participant # Exit early if participant not found
  
    reviewer = find_or_create_reviewer(session[:user].id, participant.assignment.id)
    review_mapping = find_or_create_review_mapping(participant.team.id, reviewer.id, participant.assignment.id)
  
    redirect_to_review(review_mapping)
  end
  

  private

  # Private Methods associated with action_allowed?: 
  # Checks if the user has permission for the given action and executes the corresponding method.
  def check_permission(action)
    return has_privileges_of?('Teaching Assistant') unless ACTION_PERMISSIONS.key?(action)

    send(ACTION_PERMISSIONS[action])
  end

  # Checks if the student has the necessary permissions and authorizations to proceed.
  def student_with_permissions?
    has_role?('Student') &&
      self_review_finished? &&
      are_needed_authorizations_present?(params[:id], 'reader', 'reviewer')
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


  # Private Methods associated with View methods:
  # Determines if the rubric changes by round and returns the corresponding questions based on the criteria.
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

  # Generates data for visualizing heat maps in the view statements.
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
  
  # Private Method associated with edit_participant_scores:
  # This method retrieves all questions from relevant questionnaires associated with this assignment. 
  def list_questions(assignment)
    assignment.questionnaires.each_with_object({}) do |questionnaire, questions|
      questions[questionnaire.id.to_s] = questionnaire.questions
    end
  end

  # Private Method associated with Update methods:
  # Displays an error message if the participant is not found.
  def handle_not_found
    flash[:error] = 'Participant not found.'
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


  # Private Methods associated with instructor_review: 
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

end







end



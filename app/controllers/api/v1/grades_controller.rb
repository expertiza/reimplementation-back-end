class Api::V1::GradesController < ApplicationController
  include GradesHelper

  def action_allowed
    permitted = check_permission(params[:requested_action])
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end

  # The view_grading_report offers instructors a comprehensive overview of all grades for an assignment.
  # It displays all participants and the reviews they have received.
  # Additionally, it provides a final score, which is the average of all reviews, and highlights the greatest
  # difference in scores among the reviews.
  def view_grading_report
    assignment_id = params[:id].to_i
    data = get_data_for_heat_map(assignment_id)
    
    render json: data, status: :ok
  end
    
  # The view_my_scores method provides participants with a detailed overview of their performance in an assignment.
  # It retrieves and their questions and calculated scores and prepares feedback summaries.
  # Additionally, it applies any penalties and determines the current stage of the assignment.
  # This method ensures participants have a comprehensive understanding of their scores and feedback
  def view_my_scores
    participant = AssignmentParticipant.find(params[:id].to_i)
    assignment = participant.assignment
    team_id = TeamsUser.team_id(participant.assignment_id, participant.user_id)
  
    questions = fetch_questionnaires_and_questions(assignment)
  
    pscore = fetch_participant_scores(participant, questions)
  
    topic_id = SignedUpTeam.find_topic_id_for_user(participant.assignment.id, participant.user_id)
    stage = participant.assignment.current_stage(topic_id)
  
    # Feedback Summary needs to be checked once
    # summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
    sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(questions, assignment, team_id, 'http://peerlogic.csc.ncsu.edu/sum/v1.0/summary/8/lsa', session)
  
    render json: {
      participant: participant,
      assignment: assignment,
      team_id: team_id,
      topic_id: topic_id,
      stage: stage,
      questions: questions,
      pscore: pscore,
      summary: sum.summary,
      avg_scores_by_round: sum.avg_scores_by_round,
      avg_scores_by_criterion: sum.avg_scores_by_criterion
    }
  end

  # The view_team method provides an alternative view for participants, focusing on team performance.
  # It retrieves the participant, assignment, and team information, and calculated scores and penalties.
  # Additionally, it prepares the necessary data for displaying team-related information.
  # This method ensures participants have a clear understanding of their team's performance and any associated penalties.


  def view_team
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    team = participant.team
    team_id = team.id
  
    questionnaires = AssignmentQuestionnaire.where(assignment_id: assignment.id).map(&:questionnaire)
    questions = retrieve_questions(questionnaires, assignment.id)
    pscore = Response.participant_scores(participant, questions)
    vmlist = process_questionare_for_team(assignment, team_id,questionnaires, team, participant)
  
    render json: {
      participant: participant,
      assignment: assignment,
      team: team,
      team_id: team_id,
      questions: questions,
      pscore: pscore,
      vmlist: vmlist
    }
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
      render json: { message: grade_message(participant) }, status: :ok
    else
      render json: { error: 'Error updating participant grade.' }, status: :unprocessable_entity
    end
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
      render json: { message: 'Grade and comment for submission successfully saved.' }, status: :ok
      return
    else
      render json: { error: 'Error saving grade and comment.' }, status: :unprocessable_entity
      return
    end
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
    

end



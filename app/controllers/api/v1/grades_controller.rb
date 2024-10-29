class Api::V1::GradesController < ApplicationController

  # Determines if the current user is able to perform :action as specified by the path parameter
  # If the user has the role of TA or higher they are granted access to all operations beyond view_team
  # Uses a switch statement for easy maintainability if added functionality is ever needed for students or
  # additional roles, to add more functionality simply add additional switch cases in the same syntax with
  # case 'action' and then some boolean check determining if that is allowed or forbidden.
  # GET /api/v1/grades/:action/action_allowed
  def action_allowed
    permitted = case params[:action]
                when 'view_team'
                  view_team_allowed?
                else
                  user_ta_privileges?
                end
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end

  # Provides the needed functionality of querying needed values from the backend db and returning them to build the
  # heat map in the frontend from the TA/staff view.  These values are set in the get_data_for_heat_map method
  # which takes the assignment id as a parameter.
  # GET /api/v1/grades/:id/view
  def view
    get_data_for_heat_map(params[:id])
    render json: {scores: @scores, assignment: @assignment, averages: @averages, avg_of_avg: @avg_of_avg, review_score_count: @review_score_count }, status: :ok
  end

  # Provides all relevant data for the student perspective for the heat map page as well as the
  # needed information to showcase the questionaires from the student view.  Additionally, handles the removal of user
  # identification in the reviews within the hide_reviewers_rom_student method.
  # GET /api/v1/grades/:id/view_team
  def view_team
    get_data_for_heat_map(params[:id])
    @scores[:participants] = hide_reviewers_from_student
    questionnaires = @assignment.questionnaires
    questions = retrieve_questions(questionnaires, @assignment.id)
    render json: {scores: @scores, assignment: @assignment, averages: @averages, avg_of_avg: @avg_of_avg, review_score_count: @review_score_count, questions: questions }, status: :ok
  end

  # Sets information required for editing the grade information, this includes the participant, questions, scores, and
  # assignment
  # GET /api/v1/grades/:id/edit
  def edit
    begin
      participant = AssignmentParticipant.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {message: "Assignment participant #{params[:id]} not found"}, status: :not_found
      return
    end
    assignment = participant.assignment
    questions = list_questions(assignment)
    scores = participant_scores(participant, questions)
    render json: {participant: participant, questions: questions, scores: scores, assignment: assignment}, status: :ok
  end

  # Provides functionality that handles informing the frontend which controller and action to direct to for instructor
  # review given the current state of the system.  The intended controller to handle the creation or editing of a review
  # is the response controller, however this method just determines if a new review must be made based on figuring out
  # whether or not an associated review_mapping exists from the participant already.  If one does they should go to
  # Response#edit and if one does not they should go to Response#new.  Only ever returns a status of ok.
  # GET /api/v1/grades/:id/instructor_review
  def instructor_review
    participant = AssignmentParticipant.find(params[:id])
    review_mapping = find_participant_review_mapping(participant)
    if review_mapping.new_record?
      render json: { controller: 'response', action: 'new', id: review_mapping.map_id, return: 'instructor'}, status: :ok
    else
      review = Response.find_by(map_id: review_mapping.map_id)
      render json: { controller: 'response', action: 'edit', id: review.id, return: 'instructor'}, status: :ok
    end
  end

  # patch method to update the information regarding the total score for an
  # associated with this participant for the current assignment, as long as the total_score
  # is different from the grade
  def update
    participant = AssignmentParticipant.find_by(id: params[:participant_id])
    team = participant.team
    team.grade_for_submission = params[:grade_for_submission]
    team.comment_for_submission = params[:comment_for_submission]
    begin
      team.save
      flash[:success] = 'Grade and comment for submission successfully saved.'
    rescue StandardError
      render json: {message: "Error occured while updating grade for team #{team.id}", error:  $ERROR_INFO}, status: :bad_request
      return
    end
    render json: { controller: 'grades', action: 'view_team', id: participant.id}, status: :ok
  end

  private

  # This method is used from edit methods
  # Finds all questions in all relevant questionnaires associated with this
  # assignment, this is a helper method
  def list_questions(assignment)
    questions = {}
    questionnaires = assignment.questionnaires
    questionnaires.each do |questionnaire|
      questionnaire[questionnaire.id.to_s.to_sym] = questionnaire.questions
    end
    questions
  end

  # Helper method to determine if a user can view their team. Returns true if they can, false if not
  def view_team_allowed?
    if user_student_privileges? # students can only see the heat map for their own team
      participant = AssignmentParticipant.find(params[:id])
      participant.user_id == session[:user_id]
    else
      true
    end
  end

  # Checks if the rubric varies by round and then returns appropriate
  # questions based on the ruling
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

  # Helper method that finds the current user from the session and then determines
  # if that user has the privileges afforded to someone with the role of TA
  # or higher
  def user_ta_privileges?
    user_id = session[:user_id]
    user = User.find(user_id)
    user.role.all_privileges_of?(Role.find_by(name: 'Teaching Assistant'))
  end

  def user_student_privileges?
    user_id = session[:user_id]
    user = User.find(user_id)
    user.role.all_privileges_of?(Role.find_by(name: 'Student'))
  end

  def review_grades(assignment, questions)
    scores = { participants: {}, teams: {} }

    # Participant scores
    assignment.participants.each do |participant|
      participant_scores = participant.participant_scores.where(assignment: assignment).map do |score_record|
        {
          question_id: score_record.question_id,
          score: score_record.score,
          total_score: score_record.total_score,
          round: score_record.round,
          question: questions.values.flatten.find { |q| q.id == score_record.question_id }
        }
      end
      # Chat GPT Assisted
      scores[:participants][participant.id.to_s.to_sym] = participant_scores

      # Team scores
      team = participant.user.teams.find_by(assignment: assignment)
      next unless team

      team_id = team.id.to_s.to_sym
      scores[:teams][team_id] ||= { scores: { avg: 0 } }

      # Calculate average score for the team
      team_scores = participant_scores.map { |s| s[:score].to_f / s[:total_score] * 100 }
      scores[:teams][team_id][:scores][:avg] = team_scores.sum / team_scores.size
    end

    scores
  end


    # from a given participant we find or create an AsssignmentParticipant to review the team of that participant, and set
  # the handle if it is a new record.  Then using this information we locate or create a ReviewResponseMap in order to
  # facilitate the response
  def find_participant_review_mapping(participant)
    reviewer = AssignmentParticipant.find_or_create_by(user_id: session[:user].id, parent_id: participant.assignment.id)
    reviewer.set_handle if reviewer.new_record?
    reviewee = participant.team
    ReviewResponseMap.find_or_create_by(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: participant.assignment.id)
  end


  # Provides a vector of averaged scores after removing all nonexistant values
  def vector(scores)
    scores[:teams].reject! { |_k, v| v[:scores][:avg].nil? }
    scores[:teams].map { |_k, v| v[:scores][:avg].to_i }
  end

  # Provides a float representing the average of the array with error handling
  def mean(array)
    return 0 if array.nil? || array.empty?
    array.sum / array.length.to_f
  end

  # Provides data for the heat maps in the view statements
  def get_data_for_heat_map(id)
    # Finds the assignment
    @assignment = Assignment.find(id)
    # Extracts the questionnaires
    @questions = filter_questionnaires(@assignment)
    @scores = review_grades(@assignment, @questions)
    @review_score_count = @scores[:teams].length # After rejecting nil scores need original length to iterate over hash
    @averages = vector(@scores)
    @avg_of_avg = mean(@averages)
  end

  # Loop to filter out reviewers
  # ChatGPT Assisted
  def hide_reviewers_from_student
    @scores[:participants].each_with_index.map do |(_, value), index|
      ["reviewer_#{index}".to_sym, value]
    end.to_h
  end
end

def retrieve_questions(questionnaires, assignment_id)
  questions = {}
  questionnaires.each do |questionnaire|
    round = AssignmentQuestionnaire.where(assignment_id: assignment_id, questionnaire_id: questionnaire.id).first&.used_in_round
    questionnaire_symbol = if round.nil?
                             questionnaire.id.to_s.to_sym
                           else
                             (questionnaire.id.to_s + round.to_s).to_sym
                           end
    questions[questionnaire_symbol] = questionnaire.questions
  end
  questions
end


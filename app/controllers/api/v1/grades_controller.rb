class Api::V1::GradesController < ApplicationController
  helper :file
  helper :submitted_content
  helper :penalty
  include PenaltyHelper
  include StudentTaskHelper
  include AssignmentHelper
  include GradesHelper
  include AuthorizationHelper
  include Scoring

# Determines if an action is allowed for users to view my scores and
#view team or if they are a TA
  def action_allowed
    permitted = case params[:action]
                when 'view_team'
                  view_team_allowed?
                else
                  user_ta_privileges?
                end
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end

  # Provides the needed functionality of rendering values required to view and render the
  # review heat map in the frontend from the TA perspecyobe
  def view
    # Finds the assignment
    assignment = Assignment.find(params[:id])
    # Extracts the questionnaires
    questions = filter_questionnaires(assignment)
    scores = review_grades(assignment, questions)
    review_score_count = scores[:teams].length # After rejecting nil scores need original length to iterate over hash
    averages = vector(scores)
    avg_of_avg = mean(averages)
    render json: {scores: scores, averages: averages, avg_of_avg: avg_of_avg, review_score_count: review_score_count }, status: :ok
  end

  # Allows the user to view information regarding their team that they have signed up with
  # This includes information such as the topic if relevant to the assignment, and some info related
  # to the rubrics or rounds of peer review
  def view_team
    @participant = AssignmentParticipant.find(params[:id])
    @assignment = @participant.assignment
    @team = @participant.team
    @team_id = @team.id
    questionnaires = @assignment.questionnaires
    @questions = retrieve_questions(questionnaires, @assignment.id)
    @pscore = participant_scores(@participant, @questions)
    @penalties = calculate_penalty(@participant.id)

    counter_for_same_rubric = 0
    questionnaires.each do |questionnaire|
      @round = nil

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
    end
    @current_role_name = session[:user].role.name
  end

  # Sets information for editing the grade information, setting the scores
  # for every question after listing the questions out
  def edit
    participant = AssignmentParticipant.find(params[:id])
    if participant.nil?
      render json: {message: "Assignment participant #{params[:id]} not found"}, status: :not_found
      return
    end
    assignment = participant.assignment
    questions = list_questions(assignment)
    scores = participant_scores(participant, questions)
    render json: {participant: participant, questions: questions, scores: scores, assignment: assignment}, status: :ok
  end

  #  Provides functionality for instructors to perform review on an assignment
  #  appropriately redirects the instructor to the correct page based on whether
  #  or not the review already exists within the system.
  def instructor_review
    participant = AssignmentParticipant.find(params[:id])
    review_mapping = find_participant_review_mapping(participant)
    if review_mapping.new_record?
      redirect_to controller: 'response', action: 'edit', id: review_mapping.map_id, return: 'instructor'
    else
      review = Response.find_by(map_id: review_mapping.map_id)
      redirect_to controller: 'response', action: 'new', id: review.id, return: 'instructor'
    end
  end

  # This method is used from edit methods
  # Finds all questions in all relevant questionnaires associated with this
  # assignment, this is a helper method
  # TODO should be private.
  def list_questions(assignment)
    questions = {}
    questionnaires = assignment.questionnaires
    questionnaires.each do |questionnaire|
      questions[questionnaire.symbol] = questionnaire.questions
    end
    questions
  end

  # patch method to update the information regarding the total score for an
  # associated with this participant for the current assignment, as long as the total_score
  # is different from the grade
  # TODO the bottom of this method where we call flash[:note] = message will work with the valid
  # TODO path but not in the case of the unless statement evaluating to true, as we never initialize
  # TODO message then, so error handling is bad here
  # FIXME potentially obsolete, remove? No API endpoint for this in the base code
  def update
    participant = AssignmentParticipant.find_by(id: params[:participant_id])
    @team = participant.team
    @team.grade_for_submission = params[:grade_for_submission]
    @team.comment_for_submission = params[:comment_for_submission]
    begin
      @team.save
      flash[:success] = 'Grade and comment for submission successfully saved.'
    rescue StandardError
      flash[:error] = $ERROR_INFO
    end
    redirect_to controller: 'grades', action: 'view_team', id: participant.id
  end

  private

  # Helper method to determine if a user can view their team. Returns true if they can, false if not
  def view_team_allowed?
    if current_user_is_a? 'Student' # students can only see the heat map for their own team
      participant = AssignmentParticipant.find(params[:id])
      current_user_is_assignment_participant?(participant.assignment.id)
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
        questions[questionnaire.symbol] = questionnaire.questions
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

  def review_grades(assignment, questions)
    scores = { participants: {}, teams: {} }
    assignment.participants.each do |participant|
      scores[:participants][participant.id.to_s.to_sym] = participant_scores(participant, questions)
    end
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
end

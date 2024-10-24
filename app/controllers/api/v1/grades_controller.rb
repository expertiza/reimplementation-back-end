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
# Determines if an action is allowed for users to view my scores and view team or if they are a TA
  def action_allowed?
    case params[:action]
    when 'view_my_scores'
      view_my_scores_allowed?
    when 'view_team'
      view_team_allowed?
    else
      user_ta_privileges?
    end
  end

  # the view grading report provides the instructor with an overall view of all the grades for
  # an assignment. It lists all participants of an assignment and all the reviews they received.
  # It also gives a final score, which is an average of all the reviews and greatest difference
  # in the scores of all the reviews.

  # Concerns: No list of all participants (Is that a requirement?) whilst mentioned in the documentation.
  # Does not list any reviews for the participants.
  # Instead it provides an (assumed) graph of scores, their averages for each question, and penalties.
  # Too many functions we cannot locally access.
  def view
    # Finds the assignment
    @assignment = Assignment.find(params[:id])
    # Extracts the questionnaires
    @questions = filter_questionnaires
    @scores = review_grades(@assignment, @questions)
    @num_reviewers_assigned_scores = @scores[:teams].length # After rejecting nil scores need original length to iterate over hash
    averages = vector(@scores)
    @average_chart = bar_chart(averages, 300, 100, 5)
    @avg_of_avg = mean(averages)
    penalties(@assignment.id)
    @show_reputation = false
  end


  # method for alternative view
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
    @vmlist = []

    counter_for_same_rubric = 0
    if @assignment.vary_by_topic?
      topic_id = SignedUpTeam.topic_id_by_team_id(@team_id)
      topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: @assignment.id, topic_id: topic_id).first&.questionnaire
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
      @vmlist << populate_view_model(questionnaire)
    end
    @current_role_name = session[:user].role.name
  end

  # Sets information for editing the grade information, setting the scores
  # for every question after listing the questions out
  def edit
    @participant = AssignmentParticipant.find(params[:id])
    @assignment = @participant.assignment
    @questions = list_questions(@assignment)
    @scores = participant_scores(@participant, @questions)
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
    participant = AssignmentParticipant.find(params[:id])
    total_score = params[:total_score]
    unless format('%.2f', total_score) == params[:participant][:grade]
      participant.update_attribute(:grade, params[:participant][:grade])
      message = if participant.grade.nil?
                  'The computed score will be used for ' + participant.user.name + '.'
                else
                  'A score of ' + grade_to_string(params) + '% has been saved for ' + participant.user.name + '.'
                end
    end
    flash[:note] = message
    redirect_to action: 'edit', id: params[:id]
  end


  def save_grade_and_comment_for_submission
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

  def redirect_when_disallowed
    # Could refactor this to two methods using disalowed and redirect
    # For author feedback, participants need to be able to read feedback submitted by other teammates.
    # If response is anything but author feedback, only the person who wrote feedback should be able to see it.
    ## This following code was cloned from response_controller.

    # ACS Check if team count is more than 1 instead of checking if it is a team assignment
    if @participant.assignment.max_team_size > 1
      team = @participant.team
      unless team.nil? || (team.users.include? session[:user])
        flash[:error] = 'You are not on the team that wrote this feedback'
        redirect_to '/'
        return true
      end
    else
      reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: @participant.assignment.id).first
      return true unless session[:user_id] == reviewer.try(:user_id)
    end
    false
  end

  def assign_all_penalties(participant, penalties)
    @all_penalties[participant.id] = {
      submission: penalties[:submission],
      review: penalties[:review],
      meta_review: penalties[:meta_review],
      total_penalty: @total_penalty
    }
  end

 
  def self_review_finished?
    participant = Participant.find(params[:id])
    assignment = participant.try(:assignment)
    self_review_enabled = assignment.try(:is_selfreview_enabled)
    not_submitted = unsubmitted_self_review?(participant.try(:id))
    if self_review_enabled
      !not_submitted
    else
      true
    end
  end
end

# Helper method to determine if a user can view their scores. Returns true if they can, false if not
def view_my_scores_allowed?
  current_user_has_student_privileges? &&
    are_needed_authorizations_present?(params[:id], 'reader', 'reviewer') &&
    self_review_finished?
end

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
def filter_questionnaires
  questionnaires = @assignment.questionnaires
  if @assignment.varying_rubrics_by_round?
    retrieve_questions(questionnaires, @assignment.id)
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

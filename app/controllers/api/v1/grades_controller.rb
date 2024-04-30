require_dependency 'scoring'
require_dependency 'grades_helper'

class Api::V1::GradesController < ApplicationController
  # before_action :set_assignment, only: [:view, :view_my_scores, :view_team]
  # rescue_from ActiveRecord::RecordNotFound, with: :assignment_not_found

  # Include necessary modules
  include Scoring
  include PenaltyHelper
  include StudentTaskHelper
  include AssignmentHelper
  include GradesHelper
  include AuthorizationHelper

  # Handles actions allowed based on user privileges and context
  # Example API call: GET 'api/v1/grades/action_allowed?action=view_my_scores&id=1'
  # Example URL: http://localhost:3002/api/v1/grades/1/action_allowed?action=view_scores&id=1
  def action_allowed
    case params[:action]
    when 'view_scores'
      if current_user_has_student_privileges? &&
        are_needed_authorizations_present?(params[:id], 'reader', 'reviewer') &&
        self_review_finished?
        render json: { allowed: true }
      else
        render json: { allowed: false, error: 'Unauthorized' }, status: :forbidden
      end
    when 'view_team'
      if current_user_is_a? 'Student'
        participant = AssignmentParticipant.find_by(id: params[:id])
        if participant && current_user_is_assignment_participant?(participant.assignment.id)
          render json: { allowed: true }
        else
          render json: { allowed: false, error: 'Unauthorized' }, status: :forbidden
        end
      else
        render json: { allowed: true }
      end
    else
      if current_user_has_ta_privileges?
        render json: { allowed: true }
      else
        render json: { allowed: false, error: 'Unauthorized' }, status: :forbidden
      end
    end
  end

  # Retrieves view data for an assignment
  # Example API call: GET /api/v1/grades/:id/view
  # Example URL: http://localhost:3002/api/v1/grades/4/view
  def view
    assignment = Assignment.find(params[:id])
    questionnaires = assignment.questionnaires
    if assignment.num_review_rounds > 1
      questions = retrieve_questions questionnaires, assignment.id
    else
      questions = {}
      questionnaires.each do |questionnaire|
        questions[questionnaire.symbol] = questionnaire.questions
      end
    end
    scores = review_grades(assignment, questions)
    num_reviewers_assigned_scores = scores[:teams].length
    averages = vector(scores)
    avg_of_avg = mean(averages)
    render json: { scores: scores, averages: averages, avg_of_avg: avg_of_avg, num_reviewers_assigned_scores: num_reviewers_assigned_scores }
  end

  # Retrieves scores view for a participant
  # Example API call: GET /api/v1/grades/:id/view_scores
  # Example URL: http://localhost:3002/api/v1/grades/1/view_scores
  def view_scores
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    topic_id = SignedUpTeam.topic_id(participant.assignment.id, participant.user_id)
    stage = assignment.current_stage(topic_id)

    render json: { participant: participant }
  end

  # Retrieves team view for a participant
  # Example API call: GET /api/v1/grades/:id/view_team
  # Example URL: http://localhost:3002/api/v1/grades/1/view_team
  def view_team
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    team = participant.team
    questionnaires = assignment.questionnaires
    questions = retrieve_questions(questionnaires, assignment.id)
    pscore = participant_scores(participant, questions)

    render json: { participant: participant, assignment: assignment, team: team, questions: questions, pscore: pscore }
  end

  # Edits data for a participant
  # Example API call: GET /api/v1/grades/:id/edit
  def edit
    assignment = AssignmentParticipant.find(params[:id])
    questions = list_questions(assignment)
    scores = participant_scores(participant, questions)

    render json: {
      participant: participant,
      assignment: assignment,
      questions: questions,
      scores: scores
    }, status: :ok
  end

  # Retrieves data for a participant
  # Example API call: GET /api/v1/grades/:id
  def show
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    questions = list_questions(assignment)
    scores = participant_scores(participant, questions)

    render json: { participant: participant, assignment: assignment, questions: questions, scores: scores }
  end

  # Updates data for a participant
  # Example API call: PUT /api/v1/grades/:id/update
  def update
    participant = AssignmentParticipant.find(params[:id])
    total_score = params[:total_score]
    unless format('%.2f', total_score) == params[:participant][:grade]
      participant.update_attribute(:grade, params[:participant][:grade])
      message = if participant.grade.nil?
                  "The computed score will be used for #{participant.user.name}."
                else
                  "A score of #{params[:participant][:grade]}% has been saved for #{participant.user.name}."
                end
    end
    render json: { message: message }
  end

  # Saves grade and comment for submission
  # Example API call: POST /api/v1/grades/:id/save_grade_and_comment_for_submission
  def save_grade_and_comment_for_submission
    participant = AssignmentParticipant.find(params[:id])
    @team = participant.team
    @team.grade_for_submission = params[:grade]
    @team.comment_for_submission = params[:comment]
    begin
      @team.save!
      render json: { success: "Grade '#{params[:grade]}' and comment '#{params[:comment]}' for submission successfully saved." }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  # Sets assignment
  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  # Lists questions for an assignment
  def list_questions(assignment)
    questions = {}
    questionnaires = assignment.questionnaires
    questionnaires.each do |questionnaire|
      questions[questionnaire.symbol] = questionnaire.questions
    end
    questions
  end

  # Checks if self review is finished
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


# def assign_all_penalties
#   participant = AssignmentParticipant.find(params[:id])
#   all_penalties = {
#     submission: params[:penalties][:submission],
#     review: params[:penalties][:review],
#     meta_review: params[:penalties][:meta_review],
#     total_penalty: @total_penalty
#   }
#   participant.update(all_penalties: all_penalties)
#   { success: true, message: 'All penalties assigned successfully' }
# rescue StandardError => e
#   { error: e.message }
# end


# GET /api/v1/grades/:id/instructor_review
# def instructor_review
#   participant = AssignmentParticipant.find(params[:id])
#   reviewer = AssignmentParticipant.find_or_create_by(user_id: session[:user].id, parent_id: participant.assignment.id)
#   reviewer.set_handle if reviewer.new_record?
#   reviewee = participant.team
#   revieweemapping = ReviewResponseMap.find_or_create_by(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: participant.assignment.id)
#
#   render json: { participant: participant, session_user: session[:user] }
# end

# def populate_view_model(questionnaire)
#   vm = VmQuestionResponse.new(questionnaire, @assignment, @round)
#   vmquestions = questionnaire.questions
#   vm.add_questions(vmquestions)
#   vm.add_team_members(@team)
#   qn = AssignmentQuestionnaire.where(assignment_id: @assignment.id, used_in_round: 2).size >= 1
#   vm.add_reviews(@participant, @team, @assignment.varying_rubrics_by_round?)
#   vm.calculate_metrics
#   vm.to_json # Convert the view model object to JSON for API response
# end

# def redirect_when_disallowed
#   if @participant.assignment.max_team_size > 1
#     team = @participant.team
#     unless team.nil? || (team.user_id? session[:user])
#       { error: 'You are not on the team that wrote this feedback' } # Return error message as JSON
#     end
#   else
#     reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: @participant.assignment.id).first
#     unless current_user_id?(reviewer.try(:user_id))
#       { error: 'Unauthorized access' } # Return error message as JSON
#     end
#   end
#   { success: true } # Return success message as JSON if conditions are met
# end

# def fetch_pscore_data(assignment)
#
# end
#
# def make_chart
#   assignment = Assignment.find(params[:id])
#   grades_bar_charts = {}
#   participant_score_types = %i[metareview feedback teammate]
#   pscore = fetch_pscore_data(assignment) # You need to implement a method to fetch pscore data
#
#   if pscore[:review]
#     scores = []
#     if assignment.varying_rubrics_by_round?
#       (1..assignment.rounds_of_reviews).each do |round|
#         responses = pscore[:review][:assessments].select { |response| response.round == round }
#         scores.concat(score_vector(responses, "review#{round}"))
#         scores -= [-1.0]
#       end
#       grades_bar_charts[:review] = bar_chart(scores)
#     else
#       grades_bar_charts[:review] = charts(:review) # Assuming charts method is defined elsewhere
#     end
#   end
#
#   participant_score_types.each { |symbol| grades_bar_charts[symbol] = charts(symbol) }
#
#   grades_bar_charts.to_json
# end

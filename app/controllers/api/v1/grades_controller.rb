# class Api::V1::GradesController < ApplicationController
#   before_action :set_assignment, only: [:view, :view_my_scores, :view_team]
#   rescue_from ActiveRecord::RecordNotFound, with: :assignment_not_found
#
#   # GET /api/v1/assignments/:id/grades
#   # View grading report for an assignment
#   def view
#     questionnaires = @assignment.questionnaires
#     if @assignment.varying_rubrics_by_round?
#       questions = retrieve_questions(questionnaires, @assignment.id)
#     else
#       questions = {}
#       questionnaires.each do |questionnaire|
#         questions[questionnaire.symbol] = questionnaire.questions
#       end
#     end
#     scores = review_grades(@assignment, questions)
#     num_reviewers_assigned_scores = scores[:teams].length
#     averages = vector(scores)
#     average_chart = bar_chart(averages, 300, 100, 5)
#     avg_of_avg = mean(averages)
#     penalties(@assignment.id)
#     show_reputation = false
#
#     render json: {
#       scores: scores,
#       num_reviewers_assigned_scores: num_reviewers_assigned_scores,
#       average_chart: average_chart,
#       avg_of_avg: avg_of_avg,
#       penalties: @penalties,
#       show_reputation: show_reputation
#     }, status: :ok
#   end
#
#   # GET /api/v1/assignments/:participant_id/view_my_scores
#   # View own scores for an assignment
#   def view_my_scores
#     participant = AssignmentParticipant.find(params[:participant_id])
#     team_id = TeamsUser.team_id(participant.parent_id, participant.user_id)
#
#     assignment = participant.assignment
#     questionnaires = assignment.questionnaires
#     questions = retrieve_questions(questionnaires, assignment.id)
#     pscore = participant_scores(participant, questions)
#     make_chart
#     topic_id = SignedUpTeam.topic_id(assignment.id, participant.user_id)
#     stage = assignment.current_stage(topic_id)
#     penalties(assignment.id)
#
#     summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
#     sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(questions, assignment, team_id, summary_ws_url, session)
#     summary = sum.summary
#     avg_scores_by_round = sum.avg_scores_by_round
#     avg_scores_by_criterion = sum.avg_scores_by_criterion
#
#     render json: {
#       participant: participant,
#       pscore: pscore,
#       charts: @grades_bar_charts,
#       topic_id: topic_id,
#       stage: stage,
#       penalties: @penalties,
#       summary: summary,
#       avg_scores_by_round: avg_scores_by_round,
#       avg_scores_by_criterion: avg_scores_by_criterion
#     }, status: :ok
#   end
#
#   # GET /api/v1/assignments/:participant_id/view_team
#   # View team scores for an assignment
#   def view_team
#     participant = AssignmentParticipant.find(params[:participant_id])
#     assignment = participant.assignment
#     team = participant.team
#     team_id = team.id
#     questionnaires = assignment.questionnaires
#     questions = retrieve_questions(questionnaires, assignment.id)
#     pscore = participant_scores(participant, questions)
#     penalties = calculate_penalty(participant.id)
#     vmlist = []
#
#     counter_for_same_rubric = 0
#     if assignment.vary_by_topic?
#       topic_id = SignedUpTeam.topic_id_by_team_id(team_id)
#       topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: assignment.id, topic_id: topic_id).first.questionnaire
#       vmlist << populate_view_model(topic_specific_questionnaire)
#     end
#
#     questionnaires.each do |questionnaire|
#       round = nil
#
#       if assignment.varying_rubrics_by_round? && questionnaire.type == 'ReviewQuestionnaire'
#         questionnaires = AssignmentQuestionnaire.where(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
#         if questionnaires.count > 1
#           round = questionnaires[counter_for_same_rubric].used_in_round
#           counter_for_same_rubric += 1
#         else
#           round = questionnaires[0].used_in_round
#           counter_for_same_rubric = 0
#         end
#       end
#       vmlist << populate_view_model(questionnaire)
#     end
#
#     current_role_name = current_role_name
#
#     render json: {
#       participant: participant,
#       assignment: assignment,
#       team: team,
#       team_id: team_id,
#       pscore: pscore,
#       penalties: penalties,
#       vmlist: vmlist,
#       current_role_name: current_role_name
#     }, status: :ok
#   end
#
#   private
#
#   def set_assignment
#     @assignment = Assignment.find(params[:id])
#   end
#
#   def assignment_not_found
#     render json: { error: "Assignment with id #{params[:id]} not found" }, status: :not_found
#   end
#
#
# end
# class Api::V1::GradesController < ApplicationController
#
#   def show
#     render json: {
#       participant: participant,
#       assignment: assignment,
#       team: team,
#       team_id: team_id,
#       pscore: pscore,
#       penalties: penalties,
#       vmlist: vmlist,
#       current_role_name: current_role_name
#     }, status: :ok
#   end
#   # GET /api/v1/grades/view_team
#   def view_team
#     participant = AssignmentParticipant.find(params[:participant_id])
#     assignment = participant.assignment
#     team = participant.team
#     team_id = team.id
#     questionnaires = assignment.questionnaires
#     questions = retrieve_questions(questionnaires, assignment.id)
#     pscore = participant_scores(participant, questions)
#     penalties = calculate_penalty(participant.id)
#     vmlist = []
#
#     puts questionnaires
#
#     counter_for_same_rubric = 0
#     if assignment.vary_by_topic?
#       topic_id = SignedUpTeam.topic_id_by_team_id(team_id)
#       topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: assignment.id, topic_id: topic_id).first.questionnaire
#       vmlist << populate_view_model(topic_specific_questionnaire)
#     end
#
#     questionnaires.each do |questionnaire|
#       round = nil
#
#       if assignment.varying_rubrics_by_round? && questionnaire.type == 'ReviewQuestionnaire'
#         questionnaires = AssignmentQuestionnaire.where(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
#         if questionnaires.count > 1
#           round = questionnaires[counter_for_same_rubric].used_in_round
#           counter_for_same_rubric += 1
#         else
#           round = questionnaires[0].used_in_round
#           counter_for_same_rubric = 0
#         end
#       end
#       vmlist << populate_view_model(questionnaire)
#     end
#     current_role_name = current_role_name
#
#     render json: {
#       participant: participant,
#       assignment: assignment,
#       team: team,
#       team_id: team_id,
#       pscore: pscore,
#       penalties: penalties,
#       vmlist: vmlist,
#       current_role_name: current_role_name
#     }, status: :ok
# #   end
require_dependency 'scoring'
require_dependency 'grades_helper'
class Api::V1::GradesController < ApplicationController
  # before_action :set_assignment, only: [:view, :view_my_scores, :view_team]
  # rescue_from ActiveRecord::RecordNotFound, with: :assignment_not_found
  include Scoring
  include PenaltyHelper
  include StudentTaskHelper
  include AssignmentHelper
  include GradesHelper
  include AuthorizationHelper

  # GET /api/v1/grades/:id/view
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
    # penalties(assignment.id)
    render json: { scores: scores, averages: averages, avg_of_avg: avg_of_avg, num_reviewers_assigned_scores: num_reviewers_assigned_scores }
  end

  # GET /api/v1/grades/:id/view_my_scores
  def view_scores
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    # questionnaires = assignment.questionnaires
    # questions = retrieve_questions questionnaires, assignment.id
    # pscore = participant_scores(participant, questions)
    topic_id = SignedUpTeam.topic_id(participant.assignment.id, participant.user_id)
    stage = assignment.current_stage(topic_id)
    penalties(assignment.id)

    render json: { stage: stage }
  end

  # GET /api/v1/grades/:id/view_team
  def view_team
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    team = participant.team
    questionnaires = assignment.questionnaires
    questions = retrieve_questions(questionnaires, assignment.id)
    pscore = participant_scores(participant, questions)
    # penalties = calculate_penalty(participant.id)

    render json: { participant: participant, assignment: assignment, team: team, questions: questions, pscore: pscore}
  end

  # GET /api/v1/grades/:id
  def show
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    questions = list_questions(assignment)
    scores = participant_scores(participant, questions)

    render json: { participant: participant, assignment: assignment, questions: questions, scores: scores }
  end

  # GET /api/v1/grades/:id/instructor_review
  def instructor_review

    participant = AssignmentParticipant.find(params[:id])
    reviewer = AssignmentParticipant.find_or_create_by(user_id: session[:user].id, parent_id: participant.assignment.id)
    reviewer.set_handle if reviewer.new_record?
    reviewee = participant.team
    review_mapping = ReviewResponseMap.find_or_create_by(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: participant.assignment.id)

    render json: { participant: participant, reviewer: reviewer, review_mapping: review_mapping }
  end

  private
  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def list_questions(assignment)
    questions = {}
    questionnaires = assignment.questionnaires
    questionnaires.each do |questionnaire|
      questions[questionnaire.symbol] = questionnaire.questions
    end
    questions
  end
end

#
# class Api::V1::GradesController < ApplicationController
#   # helper :file
#   # helper :submitted_content
#   # helper :penalty
#   include PenaltyHelper
#   include StudentTaskHelper
#   include AssignmentHelper
#   include GradesHelper
#   include AuthorizationHelper
#   # include Scoring
#
#   def action_allowed?
#     case params[:action]
#     when 'view_my_scores'
#       current_user_has_student_privileges? &&
#         are_needed_authorizations_present?(params[:id], 'reader', 'reviewer') &&
#         self_review_finished?
#     when 'view_team'
#       if current_user_is_a? 'Student' # students can only see the heat map for their own team
#         participant = AssignmentParticipant.find(params[:id])
#         current_user_is_assignment_participant?(participant.assignment.id)
#       else
#         true
#       end
#     else
#       current_user_has_ta_privileges?
#     end
#   end
#
#   def controller_locale
#     locale_for_student
#   end
#
#   # the view grading report provides the instructor with an overall view of all the grades for
#   # an assignment. It lists all participants of an assignment and all the reviews they received.
#   # It also gives a final score, which is an average of all the reviews and greatest difference
#   # in the scores of all the reviews.
#   def view
#     @assignment = Assignment.find(params[:id])
#     questionnaires = @assignment.questionnaires
#     if @assignment.varying_rubrics_by_round?
#       @questions = retrieve_questions questionnaires, @assignment.id
#     else
#       @questions = {}
#       questionnaires.each do |questionnaire|
#         @questions[questionnaire.symbol] = questionnaire.questions
#       end
#     end
#     @scores = review_grades(@assignment, @questions)
#     @num_reviewers_assigned_scores = @scores[:teams].length # After rejecting nil scores need original length to iterate over hash
#     averages = vector(@scores)
#     @average_chart = bar_chart(averages, 300, 100, 5)
#     @avg_of_avg = mean(averages)
#     penalties(@assignment.id)
#     @show_reputation = false
#   end
#
#   def view_my_scores
#     @participant = AssignmentParticipant.find(params[:id])
#     @team_id = TeamsUser.team_id(@participant.parent_id, @participant.user_id)
#     return if redirect_when_disallowed
#
#     @assignment = @participant.assignment
#     questionnaires = @assignment.questionnaires
#     @questions = retrieve_questions questionnaires, @assignment.id
#     # @pscore has the newest versions of response for each response map, and only one for each response map (unless it is vary rubric by round)
#     @pscore = participant_scores(@participant, @questions)
#     make_chart
#     @topic_id = SignedUpTeam.topic_id(@participant.assignment.id, @participant.user_id)
#     @stage = @participant.assignment.current_stage(@topic_id)
#     penalties(@assignment.id)
#     # prepare feedback summaries
#     summary_ws_url = WEBSERVICE_CONFIG['summary_webservice_url']
#     sum = SummaryHelper::Summary.new.summarize_reviews_by_reviewee(@questions, @assignment, @team_id, summary_ws_url, session)
#     @summary = sum.summary
#     @avg_scores_by_round = sum.avg_scores_by_round
#     @avg_scores_by_criterion = sum.avg_scores_by_criterion
#   end
#
#   # method for alternative view
#   def view_team
#     @participant = AssignmentParticipant.find(params[:id])
#     @assignment = @participant.assignment
#     @team = @participant.team
#     @team_id = @team.id
#     questionnaires = @assignment.questionnaires
#     @questions = retrieve_questions(questionnaires, @assignment.id)
#     @pscore = participant_scores(@participant, @questions)
#     @penalties = calculate_penalty(@participant.id)
#     @vmlist = []
#
#     counter_for_same_rubric = 0
#     if @assignment.vary_by_topic?
#       topic_id = SignedUpTeam.topic_id_by_team_id(@team_id)
#       topic_specific_questionnaire = AssignmentQuestionnaire.where(assignment_id: @assignment.id, topic_id: topic_id).first.questionnaire
#       @vmlist << populate_view_model(topic_specific_questionnaire)
#     end
#     questionnaires.each do |questionnaire|
#       @round = nil
#
#       # Guard clause to skip questionnaires that have already been populated for topic specific reviewing
#       if @assignment.vary_by_topic? && questionnaire.type == 'ReviewQuestionnaire'
#         next # Assignments with topic specific rubrics cannot have multiple rounds of review
#       end
#
#       if @assignment.varying_rubrics_by_round? && questionnaire.type == 'ReviewQuestionnaire'
#         questionnaires = AssignmentQuestionnaire.where(assignment_id: @assignment.id, questionnaire_id: questionnaire.id)
#         if questionnaires.count > 1
#           @round = questionnaires[counter_for_same_rubric].used_in_round
#           counter_for_same_rubric += 1
#         else
#           @round = questionnaires[0].used_in_round
#           counter_for_same_rubric = 0
#         end
#       end
#       @vmlist << populate_view_model(questionnaire)
#     end
#     @current_role_name = current_role_name
#   end
#
#   def edit
#     @participant = AssignmentParticipant.find(params[:id])
#     @assignment = @participant.assignment
#     @questions = list_questions(@assignment)
#     @scores = participant_scores(@participant, @questions)
#   end
#
#   def instructor_review
#     participant = AssignmentParticipant.find(params[:id])
#     reviewer = AssignmentParticipant.find_or_create_by(user_id: session[:user].id, parent_id: participant.assignment.id)
#     reviewer.set_handle if reviewer.new_record?
#     review_exists = true
#     reviewee = participant.team
#     review_mapping = ReviewResponseMap.find_or_create_by(reviewee_id: reviewee.id, reviewer_id: reviewer.id, reviewed_object_id: participant.assignment.id)
#     if review_mapping.new_record?
#       review_exists = false
#     else
#       review = Response.find_by(map_id: review_mapping.map_id)
#     end
#     if review_exists
#       redirect_to controller: 'response', action: 'edit', id: review.id, return: 'instructor'
#     else
#       redirect_to controller: 'response', action: 'new', id: review_mapping.map_id, return: 'instructor'
#     end
#   end
#
#   # This method is used from edit methods
#   def list_questions(assignment)
#     questions = {}
#     questionnaires = assignment.questionnaires
#     questionnaires.each do |questionnaire|
#       questions[questionnaire.symbol] = questionnaire.questions
#     end
#     questions
#   end
#
#   def update
#     participant = AssignmentParticipant.find(params[:id])
#     total_score = params[:total_score]
#     unless format('%.2f', total_score) == params[:participant][:grade]
#       participant.update_attribute(:grade, params[:participant][:grade])
#       message = if participant.grade.nil?
#                   'The computed score will be used for ' + participant.user.name + '.'
#                 else
#                   'A score of ' + params[:participant][:grade] + '% has been saved for ' + participant.user.name + '.'
#                 end
#     end
#     flash[:note] = message
#     redirect_to action: 'edit', id: params[:id]
#   end
#
#   def save_grade_and_comment_for_submission
#     participant = AssignmentParticipant.find_by(id: params[:participant_id])
#     @team = participant.team
#     @team.grade_for_submission = params[:grade_for_submission]
#     @team.comment_for_submission = params[:comment_for_submission]
#     begin
#       @team.save
#       flash[:success] = 'Grade and comment for submission successfully saved.'
#     rescue StandardError
#       flash[:error] = $ERROR_INFO
#     end
#     redirect_to controller: 'grades', action: 'view_team', id: participant.id
#   end
#
#   def bar_chart(scores, width = 100, height = 100, spacing = 1)
#     link = nil
#     GoogleChart::BarChart.new("#{width}x#{height}", ' ', :vertical, false) do |bc|
#       data = scores
#       bc.data 'Line green', data, '990000'
#       bc.axis :y, range: [0, data.max], positions: data.minmax
#       bc.show_legend = false
#       bc.stacked = false
#       bc.width_spacing_options(bar_width: (width - 30) / (data.size + 1), bar_spacing: 1, group_spacing: spacing)
#       bc.data_encoding = :extended
#       link = bc.to_url
#     end
#     link
#   end
#
#   private
#
#   def populate_view_model(questionnaire)
#     vm = VmQuestionResponse.new(questionnaire, @assignment, @round)
#     vmquestions = questionnaire.questions
#     vm.add_questions(vmquestions)
#     vm.add_team_members(@team)
#     qn = AssignmentQuestionnaire.where(assignment_id: @assignment.id, used_in_round: 2).size >= 1
#     vm.add_reviews(@participant, @team, @assignment.varying_rubrics_by_round?)
#     vm.calculate_metrics
#     vm
#   end
#
#   def redirect_when_disallowed
#     # For author feedback, participants need to be able to read feedback submitted by other teammates.
#     # If response is anything but author feedback, only the person who wrote feedback should be able to see it.
#     ## This following code was cloned from response_controller.
#
#     # ACS Check if team count is more than 1 instead of checking if it is a team assignment
#     if @participant.assignment.max_team_size > 1
#       team = @participant.team
#       unless team.nil? || (team.user? session[:user])
#         flash[:error] = 'You are not on the team that wrote this feedback'
#         redirect_to '/'
#         return true
#       end
#     else
#       reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: @participant.assignment.id).first
#       return true unless current_user_id?(reviewer.try(:user_id))
#     end
#     false
#   end
#
#   def assign_all_penalties(participant, penalties)
#     @all_penalties[participant.id] = {
#       submission: penalties[:submission],
#       review: penalties[:review],
#       meta_review: penalties[:meta_review],
#       total_penalty: @total_penalty
#     }
#   end
#
#   def make_chart
#     @grades_bar_charts = {}
#     participant_score_types = %i[metareview feedback teammate]
#     if @pscore[:review]
#       scores = []
#       if @assignment.varying_rubrics_by_round?
#         (1..@assignment.rounds_of_reviews).each do |round|
#           responses = @pscore[:review][:assessments].select { |response| response.round == round }
#           scores = scores.concat(score_vector(responses, 'review' + round.to_s))
#           scores -= [-1.0]
#         end
#         @grades_bar_charts[:review] = bar_chart(scores)
#       else
#         charts(:review)
#       end
#     end
#     participant_score_types.each { |symbol| charts(symbol) }
#   end
#
#   def self_review_finished?
#     participant = Participant.find(params[:id])
#     assignment = participant.try(:assignment)
#     self_review_enabled = assignment.try(:is_selfreview_enabled)
#     not_submitted = unsubmitted_self_review?(participant.try(:id))
#     if self_review_enabled
#       !not_submitted
#     else
#       true
#     end
#   end
# end
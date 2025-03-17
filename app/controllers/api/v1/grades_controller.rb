class Api::V1::GradesController < ApplicationController
  include AuthorizationHelper

  def action_allowed?
    permitted = case params[:action]
                when 'view_team'
                  has_role?('Student') 
                else
                  has_privileges_of?('Teaching Assistant')
                end
    render json: { allowed: permitted }, status: permitted ? :ok : :forbidden
  end


  def edit
    @participant = AssignmentParticipant.find(params[:id])
    if @participant.nil?
      render json: { message: "Assignment participant #{params[:id]} not found" }, status: :not_found
      return
    end
    @assignment = @participant.assignment
    @questions = list_questions(@assignment)
    @scores = participant_scores(@participant, @questions)
  end

  def list_questions(assignment)
    assignment.questionnaires.each_with_object({}) do |questionnaire, questions|
      questions[questionnaire.id.to_s] = questionnaire.questions
    end
  end

  def update
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

  private

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
end


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

def get_data_for_heat_map(id)
  # Finds the assignment
  @assignment = Assignment.find(id)
  # Extracts the questionnaires
  @questions = filter_questionnaires(@assignment)
  @scores = review_grades(@assignment, @questions)
  @review_score_count = @scores[:participants].length # After rejecting nil scores need original length to iterate over hash
  @averages = filter_scores(@scores[:teams])
  @avg_of_avg = mean(@averages)
end
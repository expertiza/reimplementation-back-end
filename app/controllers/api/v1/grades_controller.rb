class Api::V1::GradesController < ApplicationController
  include AuthorizationHelper

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

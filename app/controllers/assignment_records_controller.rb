# frozen_string_literal: true

class AssignmentRecordsController < ApplicationController
  def action_allowed?
    case params[:action]
    when 'index'
      course = Course.find_by(id: params[:course_id])
      return current_user_has_instructor_privileges? || current_user_has_ta_privileges? if course.nil?

      current_user_teaching_staff_of_course?(course)
    else
      false
    end
  end

  # GET /assignment_records
  # Returns a table for all assignments in the given course,
  # with students as rows and assignments as horizontal columns.
  def index
    course = Course.find_by(id: params[:course_id])
    return render json: { error: 'Course not found' }, status: :not_found unless course

    assignments = course.assignments.order(:id)
    participants = AssignmentParticipant
      .includes(:user, :assignment)
      .where(parent_id: assignments.select(:id))

    student_rows = participants
      .group_by(&:user_id)
      .values
      .map { |student_participants| build_student_row(assignments, student_participants) }
      .sort_by { |row| row[:user_name].downcase }

    render json: {
      course_id: course.id,
      course_name: course.name,
      assignments: assignments.map { |assignment| assignment_column(assignment) },
      students: student_rows
    }, status: :ok
  end

  private

  def current_user_teaching_staff_of_course?(course)
    user_logged_in? && (
      course.instructor_id == current_user.id ||
      TaMapping.exists?(user_id: current_user.id, course_id: course.id)
    )
  end

  def assignment_column(assignment)
    {
      assignment_id: assignment.id,
      assignment_name: assignment.name,
      has_topics: assignment.has_topics
    }
  end

  def build_student_row(assignments, student_participants)
    first_participant = student_participants.first
    participant_by_assignment = student_participants.index_by(&:parent_id)

    {
      user_id: first_participant.user_id,
      user_name: first_participant.user_name,
      assignments: assignments.to_h do |assignment|
        participant = participant_by_assignment[assignment.id]
        [assignment.id.to_s, participant ? build_assignment_cell(assignment, participant) : nil]
      end
    }
  end

  def build_assignment_cell(assignment, participant)
    team = participant.team

    cell = {
      participant_id: participant.id,
      peer_grade: team&.aggregate_review_grade,
      instructor_grade: team&.grade_for_submission,
      avg_teammate_score: participant.aggregate_teammate_review_grade(teammate_review_maps_for(assignment, participant))
    }

    cell[:topic] = topic_name_for(assignment, participant) if assignment.has_topics
    cell
  end

  def topic_name_for(assignment, participant)
    return unless assignment.has_topics

    team_id = TeamsParticipant.find_by(participant_id: participant.id)&.team_id
    return unless team_id

    SignedUpTeam.find_by(team_id: team_id)&.project_topic&.topic_name
  end

  def teammate_review_maps_for(assignment, participant)
    TeammateReviewResponseMap.where(reviewed_object_id: assignment.id, reviewee_id: participant.id)
  end
end

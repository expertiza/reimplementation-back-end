# frozen_string_literal: true

class CourseReportsController < ApplicationController
  class FinalDueDateNotReviewDeadlineError < StandardError; end

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

  # GET /course_reports
  # Returns a table for all assignments in the given course,
  # with students as rows and assignments as horizontal columns.
  def index
    course = Course.find_by(id: params[:course_id])
    return render json: { error: 'Course not found' }, status: :not_found unless course

    assignments = assignments_ordered_by_final_review_due_date(course)
    assignment_ids = assignments.map(&:id)
    participants = AssignmentParticipant
      .includes(:user, :assignment)
      .where(parent_id: assignment_ids)

    student_rows = participants
      .group_by(&:user_id)
      .values
      .map { |student_participants| build_student_row(assignments, student_participants) }
      .sort_by { |row| row[:user_name].downcase }

    render json: course_report_response(course, assignments, student_rows), status: :ok
  rescue FinalDueDateNotReviewDeadlineError => e
    render json: { error: e.message }, status: :internal_server_error
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
      has_topics: !!assignment.has_topics
    }
  end

  def assignments_ordered_by_final_review_due_date(course)
    course.assignments.includes(:due_dates).sort_by do |assignment|
      [final_review_due_date_for(assignment), assignment.id]
    end
  end

  def final_review_due_date_for(assignment)
    final_due_date = assignment.due_dates.max_by(&:due_at)
    return final_due_date.due_at if final_due_date&.deadline_type_id == DueDate::REVIEW_DEADLINE_TYPE_ID

    raise FinalDueDateNotReviewDeadlineError,
          "Final due date for assignment #{assignment.id} is not a review deadline"
  end

  def course_report_response(course, assignments, student_rows)
    {
      course_id: course.id,
      course_name: course.name,
      assignments: assignments.map { |assignment| assignment_column(assignment) },
      students: student_rows
    }
  end

  def build_student_row(assignments, student_participants)
    first_participant = student_participants.first
    participant_by_assignment = student_participants.index_by(&:parent_id)

    {
      user_id: first_participant.user_id,
      user_name: first_participant.user_name,
      assignments: assignment_cells_for_student(assignments, participant_by_assignment)
    }
  end

  def assignment_cells_for_student(assignments, participant_by_assignment)
    assignments.to_h do |assignment|
      participant = participant_by_assignment[assignment.id]
      [assignment.id.to_s, participant ? build_assignment_cell(assignment, participant) : nil]
    end
  end

  def build_assignment_cell(assignment, participant)
    team = participant.team

    {
      participant_id: participant.id,
      peer_grade: team&.aggregate_review_grade,
      instructor_grade: team&.grade_for_submission,
      avg_teammate_score: participant.aggregate_teammate_review_grade(teammate_review_maps_for(assignment, participant)),
      avg_author_feedback_score: participant.aggregate_teammate_review_grade(author_feedback_maps_for(assignment, participant))
    }.tap do |cell|
      cell[:topic] = topic_name_for(assignment, participant) if assignment.has_topics
    end
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

  def author_feedback_maps_for(assignment, participant)
    review_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, reviewer_id: participant.id)

    FeedbackResponseMap.where(reviewed_object_id: review_maps.select(:id), reviewee_id: participant.id)
  end
end

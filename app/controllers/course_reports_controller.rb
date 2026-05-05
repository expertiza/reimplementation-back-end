# frozen_string_literal: true

class CourseReportsController < ApplicationController
  class FinalDueDateNotReviewDeadlineError < StandardError; end

  # only restruct for course staff (TA + instr)
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

    assignments = assignments_ordered_by(course, :final_review_due_date)
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

  # metadata col
  # indicates whether an assignment has optional columns eg topics.
  def assignment_column(assignment)
    {
      assignment_id: assignment.id,
      assignment_name: assignment.name,
      has_topics: !!assignment.has_topics
    }
  end

  def assignments_ordered_by(course, field)
    course.assignments.includes(:due_dates).sort_by do |assignment|
      [assignment_sort_value(assignment, field), assignment.id]
    end
  end

  def assignment_sort_value(assignment, field)
    case field
    when :final_review_due_date
      final_review_due_date_for(assignment)
    else
      assignment.public_send(field)
    end
  end

  # function to retrieve final review due date from the db:
  # Raises FinalDueDateNotReviewDeadline as error
  def final_review_due_date_for(assignment)
    final_due_date = assignment.due_dates.max_by(&:due_at)
    return final_due_date.due_at if final_due_date&.deadline_type_id == DueDate::REVIEW_DEADLINE_TYPE_ID

    # At this point of the project, all assignments are peer review assignments,
    # so the final deadline is bound to be a review deadline, hence this guard
    # 
    #Replace this with code in the incident that non peer review assignments are introduced
    raise FinalDueDateNotReviewDeadlineError,
          "Final due date for assignment #{assignment.id} is not a review deadline"
  end

  # function to build full response, along with the metadata + student rows.
  def course_report_response(course, assignments, student_rows)
    {
      course_id: course.id,
      course_name: course.name,
      assignments: assignments.map { |assignment| assignment_column(assignment) },
      students: student_rows
    }
  end

  # function to build each row of students (students x assignment matrix)
  def build_student_row(assignments, student_participants)
    first_participant = student_participants.first
    participant_by_assignment = student_participants.index_by(&:parent_id)

    {
      user_id: first_participant.user_id,
      user_name: first_participant.user_name,
      assignments: assignment_cells_for_student(assignments, participant_by_assignment)
    }
  end

  # per user assignment stats, combines assignment cells (next call )with student row
  def assignment_cells_for_student(assignments, participant_by_assignment)
    assignments.to_h do |assignment|
      participant = participant_by_assignment[assignment.id]
      [assignment.id.to_s, participant ? build_assignment_cell(assignment, participant) : nil]
    end
  end

  # building per-assignment cell. each cell corresponds to each assignment in a single student row.
  def build_assignment_cell(assignment, participant)
    team = participant.team

    {
      participant_id: participant.id,
      peer_grade: team&.aggregate_review_grade,
      instructor_grade: team&.grade_for_submission,
      avg_teammate_score: participant.aggregate_teammate_review_grade(teammate_review_maps_for(assignment, participant)),
      avg_author_feedback_score: participant.aggregate_teammate_review_grade(author_feedback_maps_for(assignment, participant))
    }.tap do |cell| # optional topic col
      cell[:topic] = topic_name_for(assignment, participant) if assignment.has_topics
    end
  end

  # get topic name if exists
  def topic_name_for(assignment, participant)
    return unless assignment.has_topics

    team_id = TeamsParticipant.find_by(participant_id: participant.id)&.team_id
    return unless team_id

    SignedUpTeam.find_by(team_id: team_id)&.project_topic&.topic_name
  end

  # response maps for teammate review.

  def teammate_review_maps_for(assignment, participant)
    TeammateReviewResponseMap.where(reviewed_object_id: assignment.id, reviewee_id: participant.id)
  end

  # response maps for auth feedback
  def author_feedback_maps_for(assignment, participant)
    review_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, reviewer_id: participant.id)

    FeedbackResponseMap.where(reviewed_object_id: review_maps.select(:id), reviewee_id: participant.id)
  end
end

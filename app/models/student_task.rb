# frozen_string_literal: true

class StudentTask
  attr_reader :participant, :assignment, :course, :team, :project_topic, :topic, :current_stage,
              :stage_deadline, :permission_granted, :deadlines, :review_grade, :team_members,
              :timeline, :feedback, :submission_feedback, :can_request_revision, :revision_request

  def initialize(participant:, assignment:, course:, team:, project_topic:, topic:, current_stage:,
                 stage_deadline:, permission_granted:, deadlines:, review_grade:, team_members:,
                 timeline:, feedback:, submission_feedback:, can_request_revision:, revision_request:)
    @participant = participant
    @assignment = assignment
    @course = course
    @team = team
    @project_topic = project_topic
    @topic = topic
    @current_stage = current_stage
    @stage_deadline = stage_deadline
    @permission_granted = permission_granted
    @deadlines = deadlines
    @review_grade = review_grade
    @team_members = team_members
    @timeline = timeline
    @feedback = feedback
    @submission_feedback = submission_feedback
    @can_request_revision = can_request_revision
    @revision_request = revision_request
  end

  def self.from_user(user)
    AssignmentParticipant.includes(:user, assignment: :course)
               .where(user_id: user.id)
               .map { |participant| from_participant(participant) }
               .sort_by { |task| [task.stage_deadline.nil? ? 1 : 0, task.stage_deadline || Time.zone.at(0), task.assignment_name] }
  end

  def self.from_participant(participant)
    assignment = participant.assignment
    team = resolve_team(participant)
    project_topic = resolve_project_topic(participant, team)
    deadlines = resolve_deadlines(assignment, project_topic)
    latest_revision_request = resolve_latest_revision_request(participant, team)

    new(
      participant: participant,
      assignment: assignment,
      course: assignment&.course,
      team: team,
      project_topic: project_topic,
      topic: resolve_topic(participant, project_topic),
      current_stage: participant.current_stage.presence || 'Unknown',
      stage_deadline: resolve_stage_deadline(participant, deadlines),
      permission_granted: participant.permission_granted,
      deadlines: deadlines,
      review_grade: resolve_review_grade(team),
      team_members: resolve_team_members(team),
      timeline: build_timeline(deadlines, participant.current_stage),
      feedback: resolve_feedback(team, assignment),
      submission_feedback: resolve_submission_feedback(team),
      can_request_revision: can_request_revision?(team, deadlines, latest_revision_request),
      revision_request: latest_revision_request
    )
  end

  def self.from_participant_id(id)
    participant = AssignmentParticipant.find_by(id: id)
    return nil unless participant

    from_participant(participant)
  end

  def assignment_name
    assignment&.name.to_s
  end

  def team_name
    team&.name.presence || (team && "Team #{team.id}")
  end

  def as_json(_options = {})
    {
      id: participant.id,
      participant_id: participant.id,
      assignment_id: assignment&.id,
      assignment: assignment_name,
      course_id: course&.id,
      course: course&.name,
      team_id: team&.id,
      team_name: team_name,
      team_members: team_members,
      topic: topic,
      topic_details: serialize_topic,
      current_stage: current_stage,
      stage_deadline: stage_deadline&.iso8601,
      permission_granted: permission_granted,
      deadlines: deadlines.map { |deadline| serialize_deadline(deadline) },
      timeline: timeline,
      feedback: feedback,
      submission_feedback: submission_feedback,
      can_request_revision: can_request_revision,
      revision_request: revision_request&.as_json,
      assignment_details: serialize_assignment,
      team_details: serialize_team,
      review_grade: review_grade
    }
  end

  class << self
    private

    def resolve_team(participant)
      participant.team || AssignmentTeam.team(participant)
    end

    def resolve_project_topic(participant, team)
      return nil unless team

      SignedUpTeam.includes(:project_topic)
                  .find_by(team_id: team.id, project_topics: { assignment_id: participant.assignment_id })
                  &.project_topic
    rescue ActiveRecord::StatementInvalid
      SignedUpTeam.includes(:project_topic)
                  .joins(:project_topic)
                  .find_by(team_id: team.id, project_topics: { assignment_id: participant.assignment_id })
                  &.project_topic
    end

    def resolve_deadlines(assignment, project_topic)
      return [] unless assignment

      relation = DueDate.where(parent_type: 'Assignment', parent_id: assignment.id)
      if project_topic
        relation = relation.or(DueDate.where(parent_type: 'ProjectTopic', parent_id: project_topic.id))
      end

      relation.sort_by(&:due_at)
    end

    def resolve_topic(participant, project_topic)
      participant.topic.presence ||
        project_topic&.topic_identifier.presence ||
        project_topic&.topic_name
    end

    def resolve_stage_deadline(participant, deadlines)
      parse_deadline(participant.stage_deadline) ||
        deadlines.find { |deadline| deadline.due_at&.future? }&.due_at ||
        deadlines.last&.due_at
    end

    def parse_deadline(value)
      return value.in_time_zone if value.respond_to?(:in_time_zone)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def resolve_review_grade(team)
      return nil unless team.respond_to?(:aggregate_review_grade)

      team.aggregate_review_grade
    rescue StandardError
      nil
    end

    def resolve_team_members(team)
      return [] unless team

      members = (team.users.to_a + team.participants.includes(:user).map(&:user)).compact.uniq(&:id)
      members.sort_by { |user| user.full_name.to_s }.map do |user|
        {
          id: user.id,
          name: user.name,
          full_name: user.full_name
        }
      end
    end

    def build_timeline(deadlines, current_stage)
      deadlines.map do |deadline|
        {
          id: deadline.id,
          label: deadline.deadline_name.presence || fallback_timeline_label(deadline),
          phase: timeline_phase(deadline),
          due_at: deadline.due_at&.iso8601,
          status: timeline_status(deadline, current_stage)
        }
      end
    end

    def resolve_feedback(team, assignment)
      return [] unless team

      Response.joins(:response_map)
              .includes(response_map: { reviewer: :user })
              .where(response_maps: { reviewee_id: team.id, reviewed_object_id: assignment&.id })
              .where(is_submitted: true)
              .order(updated_at: :desc)
              .map do |response|
        {
          response_id: response.id,
          reviewer_name: response.response_map.reviewer&.fullname,
          comment: response.additional_comment,
          submitted_at: response.updated_at&.iso8601
        }
      end
    end

    def resolve_submission_feedback(team)
      return nil unless team
      return nil if team.grade_for_submission.nil? && team.comment_for_submission.blank?

      {
        grade_for_submission: team.grade_for_submission,
        comment_for_submission: team.comment_for_submission
      }
    end

    def resolve_latest_revision_request(participant, team)
      return nil unless participant && team

      RevisionRequest.where(participant_id: participant.id, team_id: team.id).order(created_at: :desc).first
    end

    def can_request_revision?(team, deadlines, latest_revision_request)
      return false unless team
      return false if [RevisionRequest::PENDING, RevisionRequest::APPROVED].include?(latest_revision_request&.status)

      deadlines.any? do |deadline|
        deadline.respond_to?(:resubmission_allowed_id) &&
          deadline.resubmission_allowed_id.present? &&
          deadline.resubmission_allowed_id != DueDate::NOT_ALLOWED &&
          (deadline.due_at.nil? || deadline.due_at.future?)
      end
    end

    def timeline_phase(deadline)
      name = deadline.deadline_name.to_s.downcase
      return 'feedback' if name.include?('feedback')
      return 'review' if name.include?('review')

      'submission'
    end

    def fallback_timeline_label(deadline)
      return "Round #{deadline.round} deadline" if deadline.round.present?

      "Deadline #{deadline.deadline_type_id}"
    end

    def timeline_status(deadline, current_stage)
      return 'current' if current_stage_matches_phase?(current_stage, timeline_phase(deadline))

      deadline.due_at&.past? ? 'completed' : 'upcoming'
    end

    def current_stage_matches_phase?(current_stage, phase)
      stage = current_stage.to_s.downcase
      return false if stage.blank?

      case phase
      when 'submission'
        stage.include?('progress') || stage.include?('start') || stage.include?('submit')
      when 'review'
        stage.include?('review')
      when 'feedback'
        stage.include?('feedback') || stage.include?('finish')
      else
        false
      end
    end
  end

  private

  def serialize_assignment
    {
      id: assignment&.id,
      name: assignment_name,
      course_id: course&.id,
      course_name: course&.name
    }
  end

  def serialize_team
    {
      id: team&.id,
      name: team_name,
      members: team_members
    }
  end

  def serialize_topic
    return nil unless project_topic || topic.present?

    {
      id: project_topic&.id,
      identifier: project_topic&.topic_identifier || topic,
      name: project_topic&.topic_name || topic
    }
  end

  def serialize_deadline(deadline)
    {
      id: deadline.id,
      name: deadline.deadline_name.presence || fallback_deadline_name(deadline),
      due_at: deadline.due_at&.iso8601,
      deadline_type_id: deadline.deadline_type_id,
      round: deadline.round,
      parent_type: deadline.parent_type,
      parent_id: deadline.parent_id
    }
  end

  def fallback_deadline_name(deadline)
    return "Round #{deadline.round} deadline" if deadline.round.present?

    "Deadline #{deadline.deadline_type_id}"
  end
end

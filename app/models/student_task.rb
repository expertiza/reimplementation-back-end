# frozen_string_literal: true

class StudentTask
  attr_reader :participant, :assignment, :course, :team, :sign_up_topic, :topic, :current_stage,
              :stage_deadline, :permission_granted, :deadlines, :review_grade, :team_members,
              :timeline, :feedback

  def initialize(participant:, assignment:, course:, team:, topic:, current_stage:,
                 stage_deadline:, permission_granted:, deadlines:, review_grade:,
                 sign_up_topic:, team_members:, timeline:, feedback:)
    @participant = participant
    @assignment = assignment
    @course = course
    @team = team
    @sign_up_topic = sign_up_topic
    @topic = topic
    @current_stage = current_stage
    @stage_deadline = stage_deadline
    @permission_granted = permission_granted
    @deadlines = deadlines
    @review_grade = review_grade
    @team_members = team_members
    @timeline = timeline
    @feedback = feedback
  end

  def self.from_user(user)
    Participant.includes(:team, assignment: :course)
               .where(user_id: user.id)
               .map { |participant| from_participant(participant) }
               .sort_by { |task| [task.stage_deadline.nil? ? 1 : 0, task.stage_deadline || Time.zone.at(0), task.assignment_name] }
  end

  def self.from_participant(participant)
    assignment = participant.assignment
    team = resolve_team(participant)
    sign_up_topic = resolve_sign_up_topic(participant, team)
    deadlines = resolve_deadlines(assignment, sign_up_topic)

    new(
      participant: participant,
      assignment: assignment,
      course: assignment&.course,
      team: team,
      sign_up_topic: sign_up_topic,
      topic: resolve_topic(participant, sign_up_topic),
      current_stage: participant.current_stage.presence || 'Unknown',
      stage_deadline: resolve_stage_deadline(participant, deadlines),
      permission_granted: participant.permission_granted,
      deadlines: deadlines,
      review_grade: nil,
      team_members: resolve_team_members(team),
      timeline: build_timeline(deadlines, participant.current_stage),
      feedback: resolve_feedback(team, assignment)
    )
  end

  def self.from_participant_id(id)
    participant = Participant.includes(:team, assignment: :course).find_by(id: id)
    return nil unless participant

    from_participant(participant)
  end

  def assignment_name
    assignment&.name.to_s
  end

  def team_name
    return nil unless team

    "Team #{team.id}"
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
      assignment_details: serialize_assignment,
      team_details: serialize_team,
      review_grade: review_grade
    }
  end

  class << self
    private

    def resolve_team(participant)
      participant.team || Team.joins(:teams_users)
                              .find_by(assignment_id: participant.assignment_id,
                                       teams_users: { user_id: participant.user_id })
    end

    def resolve_sign_up_topic(participant, team)
      return nil unless team

      SignedUpTeam.joins(:sign_up_topic)
                  .includes(:sign_up_topic)
                  .find_by(team_id: team.id, sign_up_topics: { assignment_id: participant.assignment_id })
                  &.sign_up_topic
    end

    def resolve_deadlines(assignment, sign_up_topic)
      relation = DueDate.where(parent_type: 'Assignment', parent_id: assignment.id)
      relation = relation.or(DueDate.where(parent_type: 'SignUpTopic', parent_id: sign_up_topic.id)) if sign_up_topic

      relation.sort_by(&:due_at)
    end

    def resolve_topic(participant, sign_up_topic)
      participant.topic.presence ||
        sign_up_topic&.topic_identifier.presence ||
        sign_up_topic&.topic_name
    end

    def resolve_stage_deadline(participant, deadlines)
      parse_deadline(participant.stage_deadline) || deadlines.find { |deadline| deadline.due_at.future? }&.due_at || deadlines.last&.due_at
    end

    def parse_deadline(value)
      return value.in_time_zone if value.respond_to?(:in_time_zone)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def resolve_team_members(team)
      return [] unless team

      users = (team.users.to_a + team.participants.includes(:user).map(&:user)).compact.uniq(&:id)

      users.sort_by { |user| user.full_name.to_s }.map do |user|
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

      relation = Response.joins(:response_map)
                         .includes(response_map: { reviewer: :user })
                         .where(response_maps: { reviewee_id: team.id })
      relation = relation.where(response_maps: { reviewed_object_id: assignment.id }) if assignment

      relation.where(is_submitted: true)
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

    def timeline_phase(deadline)
      name = deadline.deadline_name.to_s.downcase
      return 'feedback' if name.include?('feedback')
      return 'review' if name.include?('review')

      'submission'
    end

    def fallback_timeline_label(deadline)
      return "Round #{deadline.round} review" if deadline.round.present?

      "Deadline #{deadline.deadline_type_id}"
    end

    def timeline_status(deadline, current_stage)
      return 'current' if current_stage_matches_phase?(current_stage, timeline_phase(deadline))

      deadline.due_at.past? ? 'completed' : 'upcoming'
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
    return nil unless sign_up_topic || topic.present?

    {
      id: sign_up_topic&.id,
      identifier: sign_up_topic&.topic_identifier || topic,
      name: sign_up_topic&.topic_name || topic
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

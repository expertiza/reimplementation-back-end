# frozen_string_literal: true

class StudentTask
  attr_accessor :assignment, :assignment_id, :current_stage, :participant, :stage_deadline, :topic, :permission_granted

  def initialize(args)
    @assignment = args[:assignment]
    @assignment_id = args[:assignment_id]
    @current_stage = args[:current_stage]
    @participant = args[:participant]
    @stage_deadline = args[:stage_deadline]
    @topic = args[:topic]
    @permission_granted = args[:permission_granted]
  end

  def self.create_from_participant(participant)
    new(
      assignment: participant.assignment&.name,
      assignment_id: participant.parent_id,
      topic: participant.topic,
      current_stage: participant.current_stage,
      stage_deadline: send(:parse_stage_deadline, participant.stage_deadline),
      permission_granted: participant.permission_granted,
      participant: participant
    )
  end

  def self.from_user(user)
    Participant.where(user_id: user.id)
               .map { |p| create_from_participant(p) }
               .sort_by(&:stage_deadline)
  end

  def self.from_participant_id(id)
    part = Participant.find_by(id: id)
    return nil unless part

    create_from_participant(part)
  end

  def self.resolve_context_for_assignment(user, assignment_id)
    participant = Participant.find_by(
      user_id: user.id,
      parent_id: assignment_id
    )
    return nil unless participant

    resolve_context_for_participant(participant)
  end

  def self.resolve_context_for_participant(participant)
    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant

    {
      participant: participant,
      team_participant: team_participant,
      assignment: participant.assignment,
      duty: team_participant.resolved_duty
    }
  end

  def self.build_tasks(context)
    assignment = context[:assignment]
    participant = context[:participant]
    team_participant = context[:team_participant]
    duty = context[:duty]

    tasks = []
    review_maps = ReviewResponseMap.where(
      reviewer_id: participant.id,
      reviewed_object_id: assignment.id
    )
    quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow
    has_existing_quiz_maps = QuizResponseMap.where(reviewer_id: participant.id).exists?

    if review_maps.any?
      review_maps.each do |review_map|
        if (duty.nil? || team_participant.allows_quiz?) && (quiz_questionnaire || has_existing_quiz_maps)
          tasks << QuizTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end

        if duty.nil? || team_participant.allows_review?
          tasks << ReviewTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end
      end
    elsif team_participant.allows_quiz? && quiz_questionnaire
      tasks << QuizTaskItem.new(
        assignment: assignment,
        team_participant: team_participant,
        review_map: nil
      )
    end

    tasks
  end

  def self.ensure_response_objects!(tasks)
    tasks.each do |task|
      task.ensure_response_map!
      task.ensure_response!
    end
  end

  def self.find_task_for_map(tasks, map_id)
    tasks.find do |task|
      map = task.response_map
      map && map.id.to_i == map_id.to_i
    end
  end

  def self.prior_tasks_complete?(tasks, current_task)
    tasks.take_while { |task| task != current_task }.all?(&:completed?)
  end

  def as_json(*)
    {
      assignment_id: assignment_id,
      participant_id: participant&.id,
      assignment: assignment,
      topic: topic,
      current_stage: current_stage,
      stage_deadline: stage_deadline,
      permission_granted: permission_granted
    }
  end

  class BaseTaskItem
    attr_reader :assignment, :team_participant, :review_map

    def initialize(assignment:, team_participant:, review_map: nil)
      @assignment = assignment
      @team_participant = team_participant
      @review_map = review_map
    end

    def participant
      team_participant.participant
    end

    def response_map
      raise NotImplementedError
    end

    def ensure_response_map!
      response_map
    end

    def ensure_response!
      map = response_map
      return if map.nil?

      Response.find_or_create_by!(
        map_id: map.id,
        round: 1
      ) do |response|
        response.is_submitted = false
      end
    end

    def completed?
      map = response_map
      return false if map.nil?

      Response.where(map_id: map.id, is_submitted: true).exists?
    end

    def to_h
      map = response_map
      {
        task_type: task_type,
        assignment_id: assignment.id,
        response_map_id: map&.id,
        response_map_type: map&.type,
        reviewee_id: map&.reviewee_id,
        team_participant_id: team_participant.id
      }
    end

    def to_task_hash
      to_h
    end
  end

  class << self
    private

    def parse_stage_deadline(value)
      return Time.current + 1.year if value.nil?

      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

      Time.zone.parse(value.to_s)
    rescue StandardError
      Time.current + 1.year
    end
  end
end

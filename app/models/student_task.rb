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

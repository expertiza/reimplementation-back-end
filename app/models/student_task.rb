# frozen_string_literal: true

class StudentTask
    attr_accessor :assignment, :assignment_id, :participant_id, :current_stage, :participant, :stage_deadline, :topic, :permission_granted

    # Initializes a new instance of the StudentTask class
    def initialize(args)
      @assignment = args[:assignment]
      @assignment_id = args[:assignment_id]
      @participant_id = args[:participant_id]
      @current_stage = args[:current_stage]
      @participant = args[:participant]
      @stage_deadline = args[:stage_deadline]
      @topic = args[:topic]
      @permission_granted = args[:permission_granted]
    end

    # create a new StudentTask instance from a Participant object.cccccccc
    def self.create_from_participant(participant)
      new(
        assignment: participant.assignment.name,                          # Name of the assignment associated with the student task
        assignment_id: participant.assignment_id,
        participant_id: participant.id,
        topic: participant.topic,                                         # Current stage of the assignment process
        current_stage: participant.current_stage,                         # Participant object
        stage_deadline: parse_stage_deadline(participant.stage_deadline), # Deadline for the current stage of the assignment
        permission_granted: participant.permission_granted,               # Topic of the assignment
        participant: participant                                          # Boolean indicating if Publishing Rights is enabled
      )
    end

    def as_json(_options = nil)
      {
        assignment: @assignment,
        assignment_id: @assignment_id,
        participant_id: @participant_id,
        current_stage: @current_stage,
        stage_deadline: @stage_deadline&.iso8601,
        topic: @topic,
        permission_granted: @permission_granted
      }
    end

    # Visible student tasks: all assignment participants for this user, except on *calibrated*
    # assignments—those only appear after the instructor adds the student as a calibration participant
    # (ResponseMap with for_calibration, reviewed_object_id = assignment, reviewee_id = participant).
    def self.from_user(user)
      parts = AssignmentParticipant.where(user_id: user.id).to_a
      return [] if parts.empty?

      assignment_ids = parts.map(&:parent_id).uniq
      calibrated_assignment_ids = Assignment.where(id: assignment_ids, is_calibrated: true).pluck(:id).to_set

      visible =
        if calibrated_assignment_ids.empty?
          parts
        else
          pairs = ResponseMap.where(
            for_calibration: true,
            reviewed_object_id: calibrated_assignment_ids.to_a,
            reviewee_id: parts.map(&:id)
          ).pluck(:reviewed_object_id, :reviewee_id).to_set

          parts.select do |p|
            next true unless calibrated_assignment_ids.include?(p.parent_id)

            pairs.include?([p.parent_id, p.id])
          end
        end

      visible.map { |participant| StudentTask.create_from_participant(participant) }
            .sort_by(&:stage_deadline)
    end

    # create a StudentTask instance from a participant of the provided id
    def self.from_participant_id(id)
      p = AssignmentParticipant.find_by(id: id)
      return nil if p.nil?

      create_from_participant(p)
    end
  
    private

    # Parses a date string to a Time object, if parsing fails, set the time to be one year after current
    def self.parse_stage_deadline(date_string)
      Time.parse(date_string)
    rescue StandardError
      Time.now + 1.year
    end
  
end

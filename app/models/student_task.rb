# frozen_string_literal: true

class StudentTask
    attr_accessor :assignment, :current_stage, :participant, :stage_deadline, :topic, :permission_granted

    # Initializes a new instance of the StudentTask class
    def initialize(args)
      @assignment = args[:assignment]
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
        topic: participant.topic,                                         # Current stage of the assignment process
        current_stage: participant.current_stage,                         # Participant object
        stage_deadline: parse_stage_deadline(participant.stage_deadline), # Deadline for the current stage of the assignment
        permission_granted: participant.permission_granted,               # Topic of the assignment
        participant: participant                                          # Boolean indicating if Publishing Rights is enabled
      )
    end


    # create an array of StudentTask instances for all participants linked to a user, sorted by deadline.
    def self.from_user(user)
      Participant.where(user_id: user.id)
                 .map { |participant| StudentTask.create_from_participant(participant) }
                 .sort_by(&:stage_deadline)
    end

    # create a StudentTask instance from a participant of the provided id
    def self.from_participant_id(id)
      create_from_participant(Participant.find_by(id: id))
    end
  
    private

    # Parses a date string to a Time object, if parsing fails, set the time to be one year after current
    def self.parse_stage_deadline(date_string)
      Time.parse(date_string)
    rescue StandardError
      Time.now + 1.year
    end
  
end

class StudentTask < ApplicationRecord
    belongs_to :assignment
    belongs_to :participant
    # attr_accessor :assignment, :current_stage, :participant, :stage_deadline, :topic
    #
    # def initialize(args)
    #   @assignment = args[:assignment]
    #   @current_stage = args[:current_stage]
    #   @participant = args[:participant]
    #   @stage_deadline = args[:stage_deadline]
    #   @topic = args[:topic]
    # end

  
    def self.create_from_participant(participant)
      unless StudentTask.find_by(assignment_id: participant.assignment.id)
        student_task = new(
          participant_id: participant.id,
          assignment_id: participant.assignment.id,
          topic: participant.topic,
          current_stage: participant.current_stage,
          stage_deadline: parse_stage_deadline(participant.stage_deadline)
        )
        student_task.save
      end
    end

    def self.from_user(user)
      participants_with_user = Participant.where(user_id: user.id).to_a

      participants_with_user.map do |participant|
        StudentTask.create_from_participant participant
      end

      participants_with_user.sort_by(&:stage_deadline)
      #
      # user.assignment_participants.includes(%i[assignment topic]).map do |participant|
      #   StudentTask.from_participant participant
      # end.sort_by(&:stage_deadline)

      participants_with_user
    end
  
    private
  
    def self.parse_stage_deadline(date_string)
      Time.parse(date_string)
    rescue StandardError
      Time.now + 1.year
    end
  
end

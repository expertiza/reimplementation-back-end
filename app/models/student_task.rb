class StudentTask
    attr_accessor :assignment, :current_stage, :participant, :stage_deadline, :topic, :permission_granted

    def initialize(args)
      @assignment = args[:assignment]
      @current_stage = args[:current_stage]
      @participant = args[:participant]
      @stage_deadline = args[:stage_deadline]
      @topic = args[:topic]
      @permission_granted = args[:permission_granted]
    end

  
    def self.create_from_participant(participant)
      new(
        assignment: participant.assignment.name,
        topic: participant.topic,
        current_stage: participant.current_stage,
        stage_deadline: parse_stage_deadline(participant.stage_deadline),
        permission_granted: participant.permission_granted,
        participant: participant
      )
    end


    def self.from_user(user)
      Participant.where(user_id: user.id)
                 .map { |participant| StudentTask.create_from_participant(participant) }
                 .sort_by(&:stage_deadline)
    end

    def self.from_participant_id(id)
      create_from_participant(Participant.find_by(id: id))
    end
  
    private
  
    def self.parse_stage_deadline(date_string)
      Time.parse(date_string)
    rescue StandardError
      Time.now + 1.year
    end
  
end

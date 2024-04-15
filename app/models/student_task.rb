class StudentTask
    attr_accessor :assignment, :current_stage, :participant, :stage_deadline, :topic

    def initialize(args)
      @assignment = args[:assignment]
      @current_stage = args[:current_stage]
      @participant = args[:participant]
      @stage_deadline = args[:stage_deadline]
      @topic = args[:topic]
    end

  
    def self.create_from_participant(participant)
      new(
        assignment: participant.assignment.name,
        topic: participant.topic,
        current_stage: participant.current_stage,
        stage_deadline: parse_stage_deadline(participant.stage_deadline)
      )
    end

    def self.from_user(user)
      participants_with_user = Participant.where(user_id: user.id).to_a

      tasks = []

      participants_with_user.map do |participant|
        tasks.append(StudentTask.create_from_participant participant)
      end

      tasks.sort_by(&:stage_deadline)

      tasks
    end
  
    private
  
    def self.parse_stage_deadline(date_string)
      Time.parse(date_string)
    rescue StandardError
      Time.now + 1.year
    end
  
end

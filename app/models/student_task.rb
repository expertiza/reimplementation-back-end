class StudentTask
    attr_accessor :assignment, :course, :current_stage, :participant, :stage_deadline, :topic, :permission_granted, :deadlines, :review_grade

    # Initializes a new instance of the StudentTask class
    def initialize(args)
      @assignment = args[:assignment]
      @course = args[:course]
      @current_stage = args[:current_stage]
      @participant = args[:participant]
      @stage_deadline = args[:stage_deadline]
      @topic = args[:topic]
      @permission_granted = args[:permission_granted]
      @team_name = args[:team_name]
      @deadlines = args[:deadlines]
      @review_grade = args[:review_grade]
    end

    # create a new StudentTask instance from a Participant object.cccccccc
    def self.create_from_participant(participant)
      new(
        assignment: participant.assignment.name,                          # Name of the assignment associated with the student task
        course: participant.assignment.course.name,
        topic: participant.topic,                                         # Current stage of the assignment process
        current_stage: participant.current_stage,                         # Participant object
        stage_deadline: parse_stage_deadline(participant.stage_deadline), # Deadline for the current stage of the assignment
        permission_granted: participant.permission_granted,               # Topic of the assignment
        deadlines: sample_deadlines,
        review_grade: generate_review_grade(participant),
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

    # Generates a sample list of assignment deadlines relative to today's date.
    # This is likely used for testing or placeholder UI data.
    def self.sample_deadlines
      today = Date.today
      [
        { id: 1, date: (today - 15).to_s, description: "Submission deadline" },
        { id: 2, date: (today - 3).to_s, description: "Round 1 peer review" },
        { id: 2, date: (today - 3).to_s, description: "Round 2 peer review" },
        { id: 2, date: (today + 7).to_s, description: "Review deadline" },
      ]
    end
    
    # Generates a simulated review grade for a participant.
    # This is likely placeholder logic for demonstration or testing purposes.
    def self.generate_review_grade(participant)
      # Randomly decide whether the participant has reviews or not
      if [true, false].sample
        reviews = rand(1..6)
        base_score_per_review = 10
        penalty_percent = [0, 10, 25, 50].sample
        raw_score = reviews * base_score_per_review
        final_score = (raw_score * (1 - penalty_percent / 100.0)).round
    
        "Score: #{final_score}/100 \n" \
        "Comment: #{reviews} reviews x #{base_score_per_review} pts/review x #{100 - penalty_percent}% = #{final_score} points \n" \
        "Explanation penalty (-#{penalty_percent}%)"
      else
        "N/A"
      end
    end
  
end

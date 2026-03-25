# Queue builder responsible for constructing ordered respondable tasks
# for a participant within an assignment.
#
# The queue is structural:
# If QuizTask object exists → quiz must be completed first
# If ReviewTask object exists → review must be completed
#
# To keep no conditional branching on roles in controllers.

module TaskOrdering
  class TaskQueue
    def initialize(assignment, team_participant)
      @assignment = assignment
      @team_participant = team_participant
    end

    # Returns ordered list of task objects
    def tasks
      TaskFactory.build(
        assignment: @assignment,
        team_participant: @team_participant
      )
    end

    # Ensures maps + responses exist for all tasks
    # Called when student opens task list
    def ensure_response_objects!
      tasks.each do |task|
        task.ensure_response_map!
        task.ensure_response!
      end
    end
  end
end
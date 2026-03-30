# frozen_string_literal: true

# Queue builder responsible for constructing ordered respondable tasks for a participant within an assignment.
#
# The queue is structural:
# If QuizTask object exists → quiz must be completed first (per review pair when applicable)
# If ReviewTask object exists → review must be completed
#
# NOTE: This rebuilds task objects every time it is called.
# Do NOT rely on object identity across multiple calls.

module TaskOrdering
  class TaskQueue
    def initialize(assignment, team_participant)
      @assignment = assignment
      @team_participant = team_participant
    end

    def tasks
      TaskFactory.build(
        assignment: @assignment,
        team_participant: @team_participant
      )
    end

    # Ensures all response maps and response records exist in the database 
    # before the controller attempts to load or display tasks. 
    def ensure_response_objects!
      tasks.each do |task|
        task.ensure_response_map!
        task.ensure_response!
      end
    end

    # Finds the task associated with a given ResponseMap id.
    # Optionally accepts a pre-built task list to avoid rebuilding tasks.
    def task_for_map_id(map_id, from_tasks = nil)
      list = from_tasks || tasks
      list.find do |t|
        m = t.response_map
        m && m.id == map_id
      end
    end

    def map_in_queue?(map_id)
      task_for_map_id(map_id).present?
    end

    # Ensures queue ordering: all tasks before the current task must be completed.
    # Used to enforce quiz-before-review ordering.
    # Must use one `tasks` array: each call to `tasks` builds new task objects, so
    # `take_while { |t| t != task }` would otherwise never match by identity.
    def prior_tasks_complete_for?(map_id)
      list = tasks
      task = task_for_map_id(map_id, list)
      return false unless task

      list.take_while { |t| t != task }.all?(&:completed?)
    end
  end
end

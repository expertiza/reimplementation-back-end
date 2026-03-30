# frozen_string_literal: true

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

    # Returns ordered list of response map ids (quiz maps first, then review maps)
    def map_ids
      tasks.filter_map do |t|
        m = t.response_map
        m&.id
      end
    end

    def ensure_response_objects!
      tasks.each do |task|
        task.ensure_response_map!
        task.ensure_response!
      end
    end

    def task_for_map_id(map_id, from_tasks = nil)
      list = from_tasks || tasks
      list.find do |t|
        m = t.response_map
        m && m.id.to_i == map_id.to_i  # normalize both sides
      end
    end

    def map_in_queue?(map_id)
      task_for_map_id(map_id).present?
    end

    def prior_tasks_complete_for?(map_id)
      list = tasks
      task = task_for_map_id(map_id, list)
      return false unless task

      list.take_while { |t| t != task }.all?(&:completed?)
    end
  end
end
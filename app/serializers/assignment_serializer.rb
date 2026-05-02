class AssignmentSerializer < ActiveModel::Serializer
     attributes :id,
                :name,
                :directory_path,
                :private,
                :spec_location,
                :max_team_size,
                :staggered_deadline,
                :require_quiz,
                :days_between_submissions,
                :review_topic_threshold,
                :rounds_of_reviews,
                :num_review_rounds,
                :calculate_penalty,
                :late_policy_id,
                :is_penalty_calculated,
                :is_calibrated,
                :has_badge,
                :instructor_id,
                :course_id,
                :has_teams,
                :has_topics,
                :vary_by_round,
                :vary_by_topic,
                :assignment_questionnaires,
                :due_dates

  def assignment_questionnaires
    object.assignment_questionnaires.includes(:questionnaire).map do |assignment_questionnaire|
      {
        id: assignment_questionnaire.id,
        used_in_round: assignment_questionnaire.used_in_round,
        project_topic_id: assignment_questionnaire.project_topic_id,
        questionnaire_id: assignment_questionnaire.questionnaire_id,
        questionnaire: assignment_questionnaire.questionnaire && {
          id: assignment_questionnaire.questionnaire.id,
          name: assignment_questionnaire.questionnaire.name
        }
      }
    end
  end

  def due_dates
    object.due_dates.map do |due_date|
      {
        id: due_date.id,
        deadline_type_id: due_date.deadline_type_id,
        round: due_date.round,
        due_at: due_date.due_at
      }
    end
  end
end

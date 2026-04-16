class AssignmentSerializer < ActiveModel::Serializer
     attributes :id, :name, :max_team_size, :course_id, :vary_by_topic, :vary_by_round
end

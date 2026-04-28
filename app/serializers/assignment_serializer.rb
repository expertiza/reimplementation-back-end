class AssignmentSerializer < ActiveModel::Serializer
     attributes :id, :name, :max_team_size, :course_id, :has_role_based_review, :assignment_duties

     def has_role_based_review
          object.assignments_duties.exists?
     end

     def assignment_duties
          object.assignments_duties.includes(:duty).map do |assignment_duty|
               {
                    duty_id: assignment_duty.duty_id,
                    duty_name: assignment_duty.duty&.name,
                    max_members_for_duty: assignment_duty.max_members_for_duty
               }
          end
     end
end

class Participant < ApplicationRecord
    belongs_to :assignment#, foreign_key: 'parent_id', inverse_of: false
    belongs_to :course
    def team
    end
    def user
    end
    def copy(assignment_id)
    end
end
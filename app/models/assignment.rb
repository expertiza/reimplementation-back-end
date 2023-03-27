class Assignment < ApplicationRecord
    has_many :participants
    belongs_to :course
end

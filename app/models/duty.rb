class Duty < ApplicationRecord
    validates :name, presence: true, uniqueness: true
    
    has_many :assignments_duties, dependent: :destroy
    has_many :assignments, through: :assignments_duties
    has_many :assignment_participants
    has_many :teammate_review_questionnaires
    belongs_to :instructor, class_name: 'User'
end
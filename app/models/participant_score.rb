class ParticipantScore < ApplicationRecord
  belongs_to :assignment_participant
  belongs_to :assignment
  belongs_to :question
end

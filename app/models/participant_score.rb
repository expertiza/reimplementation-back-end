class ParticipantScore < ApplicationRecord
  belongs_to :assignment_participant, class_name: 'AssignmentParticipant', foreign_key: 'assignment_participant_id'
  belongs_to :assignment
  belongs_to :question

end

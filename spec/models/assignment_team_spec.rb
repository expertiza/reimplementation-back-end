require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }
  let(:user) { create(:user) }

  describe '#add_participant' do
    context 'when participant is not in the team' do
      it 'adds the participant successfully' do
        expect(team.add_participant(assignment.id, user)).to be_truthy
        expect(AssignmentParticipant.exists?(parent_id: assignment.id, user_id: user.id)).to be true
      end
    end

    context 'when participant already exists' do
      it 'does not create a duplicate' do
        team.add_participant(assignment.id, user)
        expect { team.add_participant(assignment.id, user) }.not_to change(AssignmentParticipant, :count)
      end
    end
  end
end

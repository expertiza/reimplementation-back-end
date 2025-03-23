require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:mentored_team, parent_id: assignment.id) }
  let(:user) { create(:user) }
  let(:mentor) { create(:user, is_mentor: true) }

  describe '#add_member' do
    context 'when user is not part of the team' do
      it 'adds the user successfully' do
        expect(team.add_member(user, assignment.id)).to be true
        expect(TeamsUser.exists?(team_id: team.id, user_id: user.id)).to be true
      end
    end

    context 'when user is already a member' do
      it 'raises an error' do
        team.add_member(user, assignment.id)
        expect { team.add_member(user, assignment.id) }.to raise_error(RuntimeError, /already a member/)
      end
    end

    context 'when mentor assignment is invalid' do
      it 'raises an error if a mentor already exists' do
        team.add_member(mentor, assignment.id)
        expect { team.add_member(create(:user, is_mentor: true), assignment.id) }.to raise_error(RuntimeError, /A mentor is already assigned/)
      end
    end
  end

  describe '#import_team_members' do
    context 'when team members are valid' do
      it 'imports members successfully' do
        row_hash = { teammembers: [user.name] }
        expect { team.import_team_members(row_hash) }.not_to raise_error
        expect(TeamsUser.exists?(team_id: team.id, user_id: user.id)).to be true
      end
    end

    context 'when a member does not exist' do
      it 'raises an ImportError' do
        row_hash = { teammembers: ['nonexistent_user'] }
        expect { team.import_team_members(row_hash) }.to raise_error(ImportError, /was not found/)
      end
    end
  end
end

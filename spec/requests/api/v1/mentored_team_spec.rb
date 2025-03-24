require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  let(:team) { create(:mentored_team) }
  let(:user) { create(:user) }
  let(:mentor) { create(:user, role: :mentor) }

  describe '#import_team_members' do
    it 'imports members successfully from a given list' do
      members = [create(:user), create(:user)]
      expect { team.import_team_members(members) }.to change { team.users.count }.by(2)
    end
  end

  describe '#find_or_raise_user' do
    it 'returns the user if found' do
      expect(team.find_or_raise_user(user.id)).to eq(user)
    end

    it 'raises an error if the user is not found' do
      expect { team.find_or_raise_user(999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#user_not_in_team?' do
    it 'returns true if user is not in the team' do
      expect(team.user_not_in_team?(user)).to be true
    end

    it 'returns false if user is in the team' do
      team.users << user
      expect(team.user_not_in_team?(user)).to be false
    end
  end

  describe '#mentor_assignment_valid?' do
    it 'returns true if a mentor can be assigned' do
      expect(team.mentor_assignment_valid?(mentor)).to be true
    end

    it 'returns false if an invalid mentor is assigned' do
      expect(team.mentor_assignment_valid?(user)).to be false
    end
  end

  describe '#add_member' do
    it 'adds a user to the team' do
      expect { team.add_member(user) }.to change { team.users.count }.by(1)
    end

    it 'does not add a user who is already in the team' do
      team.users << user
      expect { team.add_member(user) }.not_to change { team.users.count }
    end
  end

  describe '#can_add_member?' do
    it 'returns true if the team can add a member' do
      expect(team.can_add_member?).to be true
    end

    it 'returns false if the team has reached its limit' do
      allow(team).to receive(:users).and_return(Array.new(10) { create(:user) })
      expect(team.can_add_member?).to be false
    end
  end

  describe '#add_team_user' do
    it 'adds a user to the team successfully' do
      expect { team.add_team_user(user) }.to change { team.users.count }.by(1)
    end
  end

  describe '#add_participant_to_team' do
    it 'adds a participant to the team' do
      participant = create(:participant)
      expect { team.add_participant_to_team(participant) }.to change { team.users.count }.by(1)
    end
  end

  describe '#assign_mentor_if_needed' do
    it 'assigns a mentor if no mentor is present' do
      team.assign_mentor_if_needed(mentor)
      expect(team.mentor).to eq(mentor)
    end

    it 'does not assign a mentor if one is already assigned' do
      existing_mentor = create(:user, role: :mentor)
      team.mentor = existing_mentor
      team.assign_mentor_if_needed(mentor)
      expect(team.mentor).to eq(existing_mentor)
    end
  end
end

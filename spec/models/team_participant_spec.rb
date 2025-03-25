require 'rails_helper'

describe TeamParticipant, type: :model do
  # Create necessary roles
  let(:instructor_role) { Role.create!(name: 'Instructor', parent_id: nil, default_page_id: nil) }
  let(:student_role)    { Role.create!(name: 'Student', parent_id: nil, default_page_id: nil) }

  # Create an instructor for the assignment
  let(:instructor) do
    User.create!(
      name: 'InstructorUser',
      email: 'instructor@example.com',
      full_name: 'Instructor Full Name',
      password_digest: 'password',
      role: instructor_role
    )
  end

  # Create an assignment associated with the instructor
  let(:assignment) do
    Assignment.create!(
      name: 'Test Assignment',
      instructor: instructor
    )
  end

  # Create a team for the assignment
  let(:team) do
    Team.create!(
      assignment: assignment
    )
  end

  # Create valid team participant users with required attributes
  let(:user1) do
    User.create!(
      name: 'User One',
      email: 'user1@example.com',
      full_name: 'User One Full Name',
      password_digest: 'password',
      role: student_role
    )
  end

  let(:user2) do
    User.create!(
      name: 'User Two',
      email: 'user2@example.com',
      full_name: 'User Two Full Name',
      password_digest: 'password',
      role: student_role
    )
  end

  # Create a TeamParticipant record for user1 (using let! to force creation)
  let!(:team_participant) do
    TeamParticipant.create!(
      user: user1,
      team: team
    )
  end

  describe '#name' do
    it 'returns the name of the associated user' do
      expect(team_participant.name).to eq(user1.name)
    end

    it 'ignores an ip_address argument and returns the name of the associated user' do
      # Even if an IP is passed, the method returns user.name
      expect(team_participant.name("127.0.0.1")).to eq(user1.name)
    end
  end

  describe '.get_team_members' do
    before do
      # Add a second team participant for the same team.
      TeamParticipant.create!(user: user2, team: team)
    end

    it 'returns the users associated with the given team id' do
      # Ensure team_participant (for user1) is created by referencing it.
      team_participant
      members = TeamParticipant.get_team_members(team.id)
      expect(members).to match_array([user1, user2])
      expect(members.count).to eq(2)
    end

    it 'returns an empty collection if no participants exist for a team' do
      new_team = Team.create!(assignment: assignment)
      members = TeamParticipant.get_team_members(new_team.id)
      expect(members).to be_empty
    end
  end

  describe '.remove_team' do
    it 'removes the team participant record for a given user and team' do
      # Ensure the record exists before removal.
      expect(TeamParticipant.find_by(user: user1, team: team)).to be_present
      TeamParticipant.remove_team(user1.id, team.id)
      expect(TeamParticipant.find_by(user: user1, team: team)).to be_nil
    end

    it 'returns nil when no matching team participant is found' do
      new_user = User.create!(
        name: 'New User',
        email: 'newuser@example.com',
        full_name: 'New User Full Name',
        password_digest: 'password',
        role: student_role
      )
      result = TeamParticipant.remove_team(new_user.id, team.id)
      expect(result).to be_nil
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      expect(team_participant.user).to eq(user1)
    end

    it 'belongs to a team' do
      expect(team_participant.team).to eq(team)
    end
  end
end

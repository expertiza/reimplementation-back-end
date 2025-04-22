require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
  before do
    $redis = double('Redis', get: '')
  end

  describe '#find_team_participants' do
    let(:instructor) do
      User.create!(
        name: 'Instructor',
        full_name: 'Dr. Smith',
        email: 'instructor@example.com',
        password: 'password',
        role: Role.find_or_create_by!(name: 'Instructor')
      )
    end

    let(:assignment) do
      Assignment.create!(
        title: 'Test Assignment',
        directory_path: 'test_path',
        max_team_size: 2,
        instructor_id: instructor.id
      )
    end

    let(:topic) do
      SignUpTopic.create!(
        topic_name: 'Topic 1',
        assignment_id: assignment.id
      )
    end

    let(:team) do
      AssignmentTeam.create!(
        name: 'Team A',
        parent_id:     assignment.id,
        assignment_id: assignment.id
      )
    end

    let(:student_role) { Role.create!(name: 'Student') }

    let(:user) do
      User.create!(
        name: 'student1',
        full_name: 'Student One',
        email: 'student1@example.com',
        password: 'password',
        role: student_role
      )
    end

    before do
      # sign up the team
      SignedUpTeam.create!(
        sign_up_topic: topic,
        team:          team,
        is_waitlisted: false
      )

      # add a participant to the team
      participant = AssignmentParticipant.create!(
        user: user,
        assignment: assignment,
        handle: 'handle'
      )
      TeamsParticipant.create!(team: team, participant: participant)
    end

    it 'returns participants with correct team and user names filled in' do
      participants = SignedUpTeam.find_team_participants(assignment.id)
      expect(participants.size).to eq(1)

      result = participants.first

      expect(result.team_id).to eq(team.id)
      expect(result.topic_id).to eq(topic.id)
      # name should be something like "[Team A] student1 "
      expect(result.name).to include(team.name)
      expect(result.name).to include(user.name)
      expect(result.team_name_placeholder).to eq(team.name)
      expect(result.user_name_placeholder).to eq(user.name)
    end

    it 'returns an empty array if there are no matching participants' do
      SignedUpTeam.destroy_all
      expect(SignedUpTeam.find_team_participants(assignment.id)).to be_empty
    end
  end
end

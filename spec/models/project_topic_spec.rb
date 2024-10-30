require 'rails_helper'

RSpec.describe ProjectTopic, type: :model do
  # Set up initial data for tests
  let!(:role) { Role.create!(name: "Professor") }
  let!(:instructor) { Instructor.create!(name: "Ed", password: "sec-Key1", full_name: "Ed Gehringer", email: "efg@ncsu.edu", role_id: role.id) }
  let!(:assignment) { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id) }
  let!(:project_topic) { ProjectTopic.create!(topic_name: "Dummy Topic", assignment_id: assignment.id, max_choosers: 3) }
  let!(:team) { Team.create!(assignment_id: assignment.id) }

  describe '#slot_available?' do
    context 'when no teams have chosen the topic' do
      it 'returns true' do
        expect(project_topic.slot_available?).to be true
      end
    end
  end

  describe '#assign_topic_to_team' do
    let(:new_sign_up) { SignedUpTeam.new(sign_up_topic_id: nil, team_id: team.id) }

    it 'assigns the topic to the team and updates waitlist status' do
      project_topic.assign_topic_to_team(new_sign_up)
      expect(new_sign_up.is_waitlisted).to be false
      expect(new_sign_up.sign_up_topic_id).to eq(project_topic.id)
    end
  end

  describe '#sign_up_team' do
    let(:new_team) { Team.create!(assignment_id: assignment.id) }

    context 'when slot is available' do
      it 'assigns the topic to the team and drops team waitlists' do
        allow(SignedUpTeam).to receive(:drop_off_team_waitlists).with(new_team.id).and_return(true)

        expect(project_topic.sign_up_team(new_team.id)).to be true
        expect(SignedUpTeam).to have_received(:drop_off_team_waitlists).with(new_team.id)
      end
    end
  end
end

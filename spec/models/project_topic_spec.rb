require 'rails_helper'

RSpec.describe ProjectTopic, type: :model do
  # Set up initial data for tests
  let!(:role) { Role.create!(name: "Professor") }
  let!(:instructor) { Instructor.create!(name: "Ed", password: "sec-Key1", full_name: "Ed Gehringer", email: "efg@ncsu.edu", role_id: role.id) }
  let!(:assignment) { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id) }
  let!(:project_topic) { ProjectTopic.create!(topic_name: "Dummy Topic", assignment_id: assignment.id, max_choosers: 3) }
  let!(:team) { Team.create!(assignment_id: assignment.id) }

  describe 'validations' do
    it 'validates max_choosers is a non-negative integer' do
      expect(project_topic).to be_valid
      project_topic.max_choosers = -1
      expect(project_topic).not_to be_valid
    end
  end

  describe '#slot_available?' do
    context 'when no teams have chosen the topic' do
      it 'returns true' do
        expect(project_topic.slot_available?).to be true
      end
    end

    context 'when no slots are available' do
      before do
        project_topic.max_choosers.times do
          SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: false, team: Team.create!(assignment_id: assignment.id))
        end
      end

      it 'returns false' do
        expect(project_topic.slot_available?).to be false
      end
    end
  end

  describe '#signup_team' do
    let(:new_team) { Team.create!(assignment_id: assignment.id) }

    context 'when slot is available' do
      it 'assigns the topic to the team and drops team waitlists' do
        allow(SignedUpTeam).to receive(:drop_off_topic_waitlists).with(new_team.id).and_return(true)

        expect(project_topic.signup_team(new_team.id)).to be true
        expect(SignedUpTeam).to have_received(:drop_off_topic_waitlists).with(new_team.id)
      end
    end

    context 'when no slots are available' do
      before do
        project_topic.max_choosers.times do
          SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: false, team: Team.create!(assignment_id: assignment.id))
        end
      end

      it 'adds the team to the waitlist' do
        expect { project_topic.signup_team(new_team.id) }.to change { SignedUpTeam.count }.by(1)
        expect(SignedUpTeam.last.is_waitlisted).to be true
      end
    end

    context 'when the team is already signed up and not waitlisted' do
      before do
        SignedUpTeam.create!(sign_up_topic_id: project_topic.id, team: team, is_waitlisted: false)
      end

      it 'returns false' do
        expect(project_topic.signup_team(team.id)).to be false
      end
    end
  end

  describe '#longest_waiting_team' do
    let!(:waitlisted_team) { SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: true, created_at: 1.day.ago, team: Team.create!(assignment_id: assignment.id)) }

    it 'returns the team that has been waitlisted the longest' do
      expect(project_topic.longest_waiting_team).to eq(waitlisted_team)
    end
  end

  describe '#drop_team_from_topic' do
    let!(:signed_up_team) { SignedUpTeam.create!(sign_up_topic_id: project_topic.id, team: team) }

    it 'removes the team from the topic' do
      expect { project_topic.drop_team_from_topic(team.id) }.to change { SignedUpTeam.count }.by(-1)
    end

    context 'when the team is not waitlisted' do
      let!(:waitlisted_team) { SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: true, created_at: 1.day.ago, team: Team.create!(assignment_id: assignment.id)) }

      it 'assigns the topic to the next waitlisted team' do
        project_topic.drop_team_from_topic(team.id)
        expect(waitlisted_team.reload.is_waitlisted).to be false
      end
    end
  end

  describe '#current_available_slots' do
    context 'when no teams have signed up' do
      it 'returns max_choosers as available slots' do
        expect(project_topic.current_available_slots).to eq(project_topic.max_choosers)
      end
    end

    context 'when some teams have signed up' do
      before do
        2.times do
          SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: false, team: Team.create!(assignment_id: assignment.id))
        end
      end

      it 'returns the remaining available slots' do
        expect(project_topic.current_available_slots).to eq(1)
      end
    end
  end
end

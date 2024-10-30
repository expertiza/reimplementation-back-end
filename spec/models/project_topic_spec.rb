require 'rails_helper'

RSpec.describe ProjectTopic, type: :model do
  # Set up initial data for tests
  # let(:instructor) { Instructor.create(firstname: "John", lastname: "Doe") }
  let!(:project_topic) { ProjectTopic.create(topic_name: "Dummy Topic", assignment_id: 1, max_choosers: 3) }
  let!(:team) { Team.create(assignment_id: 1) }
  let!(:assignment) { Assignment.create(name: "Assignment 1") }

  describe '#slot_available?' do
    context 'when no teams have chosen the topic' do
      it 'returns true' do
        expect(project_topic.slot_available?).to be true
      end
    end

    context 'when the number of teams who chose the topic is less than max choosers' do
      before do
        # Create a signed up team directly without using a factory
        SignedUpTeam.create(sign_up_topic_id: project_topic.id, team: team, is_waitlisted: false)
      end

      it 'returns true' do
        expect(project_topic.slot_available?).to be true
      end
    end

    context 'when the number of teams who chose the topic reaches max choosers' do
      before do
        # Create signed up teams directly
        SignedUpTeam.create(sign_up_topic_id: project_topic.id, team: team, is_waitlisted: false)
        SignedUpTeam.create(sign_up_topic_id: project_topic.id, team: Team.create(assignment_id: 1), is_waitlisted: false)
        SignedUpTeam.create(sign_up_topic_id: project_topic.id, team: Team.create(assignment_id: 1), is_waitlisted: false)
      end

      it 'returns false' do
        expect(project_topic.slot_available?).to be false
      end
    end
  end

  describe '#find_team_project_topics' do
    it 'returns the topics signed up by a specific team' do
      signed_up_team = SignedUpTeam.create(sign_up_topic_id: project_topic.id, team_id: team.id)
      result = project_topic.find_team_project_topics(assignment.id, team.id)
      expect(result.first.topic_id).to eq(project_topic.id)
    end
  end

  describe '#assign_topic_to_team' do
    let(:new_sign_up) { SignedUpTeam.new(sign_up_topic_id: nil, team: team) }

    it 'assigns the topic to the team and updates waitlist status' do
      project_topic.assign_topic_to_team(new_sign_up)
      expect(new_sign_up.is_waitlisted).to be false
      expect(new_sign_up.sign_up_topic_id).to eq(project_topic.id)
    end
  end

  describe '#save_waitlist_entry' do
    let(:new_sign_up) { SignedUpTeam.new(sign_up_topic_id: nil, team_id: team.id) }

    it 'sets the is_waitlisted attribute to true and saves the entry' do
      expect(project_topic.save_waitlist_entry(new_sign_up)).to be true
      expect(new_sign_up.is_waitlisted).to be true
    end
  end

  describe '#sign_up_team' do
    let(:new_team) { Team.create(assignment_id: 1) }

    context 'when the team has already signed up and is not waitlisted' do
      before do
        SignedUpTeam.create(sign_up_topic_id: project_topic.id, team: new_team, is_waitlisted: false)
      end

      it 'returns false' do
        expect(project_topic.sign_up_team(new_team.id)).to be false
      end
    end

    context 'when slot is available' do
      it 'assigns the topic to the team and drops team waitlists' do
        allow(SignedUpTeam).to receive(:drop_off_team_waitlists).with(new_team.id).and_return(true)

        expect(project_topic.sign_up_team(new_team.id)).to be true
        expect(SignedUpTeam).to have_received(:drop_off_team_waitlists).with(new_team.id)
      end
    end

    context 'when no slot is available' do
      before do
        # Create signed up teams directly
        SignedUpTeam.create(sign_up_topic: project_topic, team: Team.create(assignment_id: 1), is_waitlisted: false)
        SignedUpTeam.create(sign_up_topic: project_topic, team: Team.create(assignment_id: 1), is_waitlisted: false)
      end

      it 'saves a waitlist entry for the team' do
        expect(project_topic.sign_up_team(new_team.id)).to be true
        last_sign_up = SignedUpTeam.last
        expect(last_sign_up.is_waitlisted).to be true
        expect(last_sign_up.team_id).to eq(new_team.id)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, assignment: assignment) }
  let(:user) { create(:user) }
  let(:participant) { create(:participant, user: user, assignment: assignment) }
  let(:reviewer) { create(:participant, assignment: assignment) }
  let(:review_response_map) { create(:review_response_map, reviewee: team, reviewer: reviewer) }

  describe '#user_id' do
    it 'returns the user_id of the first team member' do
      team.users << user
      expect(team.user_id).to eq(user.id)
    end
    it 'returns current_user.id if they are in the team' do
      team.users << user
      expect(team.user_id(user)).to eq(user.id)
    end
  end

  describe '#includes?' do
    it 'returns true if a participant is in the team' do
      allow(team).to receive(:participants).and_return([participant])
      expect(team.includes?(participant)).to be true
    end

    it 'returns false if a participant is not in the team' do
      allow(team).to receive(:participants).and_return([])
      expect(team.includes?(participant)).to be false
    end
  end

  describe '#parent_model' do
    it 'returns "Assignment"' do
      expect(team.parent_model).to eq('Assignment')
    end
  end

  describe '#assign_reviewer' do
    it 'raises an error if the assignment is not found' do
      allow(Assignment).to receive(:find_by).and_return(nil)
      expect { team.assign_reviewer(reviewer) }.to raise_error('The assignment cannot be found.')
    end

    it 'creates a review map for the reviewer' do
      expect { team.assign_reviewer(reviewer) }.to change { ReviewResponseMap.count }.by(1)
    end
  end

  describe '#create_review_map' do
    it 'creates a new ReviewResponseMap' do
      expect {
        team.create_review_map(reviewer, assignment)
      }.to change { ReviewResponseMap.count }.by(1)
    end
  end

  describe '#reviewed_by?' do
    it 'returns true if the team has been reviewed by the given reviewer' do
      review_response_map
      expect(team.reviewed_by?(reviewer)).to be true
    end

    it 'returns false if the team has not been reviewed by the given reviewer' do
      expect(team.reviewed_by?(reviewer)).to be false
    end
  end

  describe '#participants' do
    it 'returns the participants of the team' do
      allow(TeamsParticipant).to receive(:team_members).with(team.id).and_return([participant])
      expect(team.participants).to include(participant)
    end
  end

  describe '#add_participant' do
    it 'adds a participant to the team' do
      expect {
        team.add_participant(assignment.id, user)
      }.to change { TeamsParticipant.count }.by(1)
    end

    it 'does not add a participant if they are already in the team' do
      team.add_participant(assignment.id, user)
      expect {
        team.add_participant(assignment.id, user)
      }.not_to change { TeamsParticipant.count }
    end
  end

  describe '#create_new_team' do
    let(:signuptopic) { create(:sign_up_topic, assignment: assignment) }

    it 'creates a new team user and associates topic' do
      expect {
        team.create_new_team(user.id, signuptopic)
      }.to change { TeamsUser.count }.by(1)
         .and change { SignedUpTeam.count }.by(1)
         .and change { TeamNode.count }.by(1)
         .and change { TeamUserNode.count }.by(1)
    end
  end

  describe '#submit_hyperlink' do
    it 'calls TeamFileService.submit_hyperlink' do
      expect(TeamFileService).to receive(:submit_hyperlink).with(team, 'http://example.com')
      team.submit_hyperlink('http://example.com')
    end
  end

  describe '#remove_hyperlink' do
    it 'calls TeamFileService.remove_hyperlink' do
      expect(TeamFileService).to receive(:remove_hyperlink).with(team, 'http://example.com')
      team.remove_hyperlink('http://example.com')
    end
  end

  describe '#has_submissions?' do
    it 'returns true if the team has submissions' do
      allow(team).to receive(:submitted_files).and_return(['file1'])
      allow(team).to receive(:submitted_hyperlinks).and_return(nil)
      expect(team.has_submissions?).to be true
    end

    it 'returns false if the team has no submissions' do
      allow(team).to receive(:submitted_files).and_return([])
      allow(team).to receive(:submitted_hyperlinks).and_return(nil)
      expect(team.has_submissions?).to be false
    end
  end

  describe '#most_recent_submission' do
    it 'returns the latest submission' do
      submission1 = create(:submission_record, team: team, assignment: assignment, updated_at: 1.day.ago)
      submission2 = create(:submission_record, team: team, assignment: assignment, updated_at: Time.current)

      expect(team.most_recent_submission).to eq(submission2)
    end
  end
end

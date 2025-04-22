require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  let(:role) { Role.create!(name: 'Student') }
  let(:instructor) do
    User.create!(
      name: 'Instructor',
      full_name: 'Instructor Name',
      email: 'instructor@example.com',
      password: 'password',
      role: Role.create!(name: 'Instructor')
    )
  end
  let(:assignment) do
    Assignment.create!(
      title: 'Assignment 1',
      instructor: instructor,
      directory_path: 'assignment1_path'
    )
  end
  let(:team) { AssignmentTeam.create!(name: 'Test Team', parent_id: assignment.id, assignment_id: assignment.id) }
  let(:user) do
    User.create!(
      name: 'Team Member',
      full_name: 'Team Member',
      email: 'member@example.com',
      password: 'password',
      role: role
    )
  end
  let(:participant_reviewer) { AssignmentParticipant.create!(user: user, assignment_id: assignment.id, handle: 'reviewer_handle') }
  let(:mock_response) do
    double('Net::HTTPResponse', code: '200', to_s: 'HTTP OK')
  end
  let(:other_team) do
    AssignmentTeam.create!(name: 'Existing Team', parent_id: assignment.id, assignment_id: assignment.id, directory_num: 5)
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user: user,
      assignment: assignment,
      handle: 'member_handle'
    )
  end

  let!(:teams_participant) do
    TeamsParticipant.create!(participant: participant, team: team)
  end

  before do
    $redis = double('Redis', get: '')
  end

  describe '#first_user_id' do
    it 'returns the ID of the first user in the team' do
      expect(team.first_user_id).to eq(user.id)
    end
  end

  describe '#review_map_type' do
    it 'returns ReviewResponseMap string' do
      expect(team.review_map_type).to eq('ReviewResponseMap')
    end
  end

  describe '#assign_reviewer' do
    it 'creates a review response map for the reviewer' do
      expect {
        team.assign_reviewer(participant_reviewer)
      }.to change { ReviewResponseMap.count }.by(1)

      map = ReviewResponseMap.last
      expect(map.reviewee_id).to eq(team.id)
      expect(map.reviewer_id).to eq(participant_reviewer.id)
      expect(map.reviewed_object_id).to eq(assignment.id)
      expect(map.team_reviewing_enabled).to eq(false)
    end
  end

  describe '#reviewer' do
    it 'returns itself' do
      expect(team.reviewer).to eq(team)
    end
  end

  describe '#reviewed_by?' do
    it 'returns true if reviewed by given reviewer' do
      ReviewResponseMap.create!(
        reviewee_id: team.id,
        reviewer_id: participant_reviewer.reviewer.id,
        reviewed_object_id: assignment.id,
        team_reviewing_enabled: false
      )
      expect(team.reviewed_by?(participant_reviewer)).to be true
    end

    it 'returns false if not reviewed by given reviewer' do
      other_user = User.create!(
        name: 'Other',
        full_name: 'Other Full',
        email: 'other@example.com',
        password: 'password',
        role: role
      )
      reviewer = double('Participant', reviewer: other_user)
      expect(team.reviewed_by?(reviewer)).to be false
    end
  end

  describe '#topic_id' do
    it 'returns the topic ID if team has signed up' do
      topic = SignUpTopic.create!(topic_identifier: 'T1', topic_name: 'Topic 1', assignment: assignment)

      SignedUpTeam.create!(team_id: team.id, sign_up_topic_id: topic.id, is_waitlisted: false)
      expect(team.topic_id).to eq(topic.id)
    end

    it 'returns nil if no topic is assigned' do
      expect(team.topic_id).to be_nil
    end
  end

  describe '#has_submissions?' do
    it 'returns true if submitted files or hyperlinks are present' do
      allow(team).to receive(:submitted_files).and_return(['file1.txt'])
      team.submitted_hyperlinks = "---\n- https://example.com\n"
      expect(team.has_submissions?).to be true
    end

    it 'returns false if nothing is submitted' do
      allow(team).to receive(:submitted_files).and_return([])
      team.submitted_hyperlinks = nil
      expect(team.has_submissions?).to be false
    end
  end

  describe '#participants' do
    it 'returns associated AssignmentParticipants for team members' do
      AssignmentParticipant.create!(user: user, assignment_id: assignment.id, handle: 'handle1')
      expect(team.participants.map(&:user_id)).to include(user.id)
    end
  end

  describe '#delete' do
    it 'removes signed up team entries and deletes the team' do
      team = AssignmentTeam.create!(name: 'To Delete', parent_id: assignment.id, assignment_id: assignment.id)

      expect {
        AssignmentTeam.remove_team_by_id(team.id)
      }.to change { AssignmentTeam.exists?(team.id) }.from(true).to(false)
    end
  end

  describe '#destroy' do
    before do
      ReviewResponseMap.create!(
        reviewee_id: team.id,
        reviewer_id: participant_reviewer.id,
        reviewed_object_id: assignment.id,
        team_reviewing_enabled: false
      )
    end

    it 'destroys all associated review response maps before team is destroyed' do
      expect {
        team.destroy
      }.to change { ReviewResponseMap.count }.by(-1)

      expect(AssignmentTeam.exists?(team.id)).to be false
    end
  end

  describe '#submitted_files' do
    context 'when directory_num is present' do
      it 'calls files and returns submitted file paths' do
        allow(team).to receive(:directory_num).and_return(1)
        allow(team).to receive(:path).and_return('/some/fake/path')
        allow(team).to receive(:files).with('/some/fake/path').and_return(['file1.txt', 'file2.txt'])

        expect(team.submitted_files).to eq(['file1.txt', 'file2.txt'])
      end
    end

    context 'when directory_num is nil' do
      it 'returns an empty array without calling files' do
        allow(team).to receive(:directory_num).and_return(nil)

        expect(team.submitted_files).to eq([])
      end
    end
  end

  describe '#import' do
    it 'raises ImportError if assignment does not exist' do
      expect {
        AssignmentTeam.import(['Team A', 'user1'], 9999, {})
      }.to raise_error(ImportError, /assignment with the id "9999" was not found/i)
    end
  
    it 'delegates to Team.import with AssignmentTeam as team type' do
      assignment = Assignment.create!(title: 'Test', instructor: instructor, directory_path: 'test_path')
      expect(Team).to receive(:import).with(['Team A', 'user1'], assignment.id, {}, AssignmentTeam)
      AssignmentTeam.import(['Team A', 'user1'], assignment.id, {})
    end
  end
  
  describe '#export' do
    it 'delegates to Team.export with AssignmentTeam as team type' do
      csv = []
      expect(Team).to receive(:export).with(csv, assignment.id, {}, AssignmentTeam)
      AssignmentTeam.export(csv, assignment.id, {})
    end
  end
  
  describe '#copy' do
    it 'copies team members to a new team' do
      new_team = AssignmentTeam.create!(name: 'Copied Team', parent_id: assignment.id, assignment_id: assignment.id)
      expect {
        team.copy(new_team)
      }.to change { TeamsParticipant.where(team_id: new_team.id).count }.by(1)

      expect(new_team.participants.map(&:user_id)).to include(user.id)
    end
  end
  
  describe '#copy_assignment_to_course' do
    it 'creates a course team and copies members' do
      instructor_role = Role.find_or_create_by!(name: 'Instructor')
      instructor = User.create!(
        name: 'Course Instructor',
        full_name: 'Course Instructor',
        email: 'instructor_course@example.com',
        password: 'password',
        role: instructor_role
      )

      institution = Institution.create!(name: 'NCSU')

      course = Course.create!(
        name: 'CSC 517',
        directory_path: 'csc517',
        institution: institution,
        instructor: instructor
      )

      expect {
        team.copy_assignment_to_course(course.id)
      }.to change { CourseTeam.count }.by(1)
    end
  end

  describe '#participant_class' do
    it 'returns AssignmentParticipant class' do
      expect(AssignmentTeam.new.participant_class).to eq(AssignmentParticipant)
    end
  end

  describe '#hyperlinks' do
    it 'returns an array when hyperlinks are present' do
      team.submitted_hyperlinks = YAML.dump(['https://example.com'])
      expect(team.hyperlinks).to eq(['https://example.com'])
    end

    it 'returns an empty array when no hyperlinks are submitted' do
      team.submitted_hyperlinks = nil
      expect(team.hyperlinks).to eq([])
    end
  end

  describe '#submit_hyperlink' do
    before do
      allow(Net::HTTP).to receive(:get_response).and_return('200')
    end

    it 'adds a valid hyperlink to submitted_hyperlinks' do
      team.submitted_hyperlinks = YAML.dump([])

      expect {
        team.submit_hyperlink('https://example.com')
      }.to change { YAML.safe_load(team.submitted_hyperlinks).length }.by(1)
    end

    it 'prepends http:// if missing' do
      team.submitted_hyperlinks = YAML.dump([])

      expect {
        team.submit_hyperlink('example.com')
      }.to change {
        YAML.safe_load(team.submitted_hyperlinks).first
      }.to('http://example.com')
    end

    it 'raises error for empty string' do
      expect {
        team.submit_hyperlink('  ')
      }.to raise_error('The hyperlink cannot be empty!')
    end
  end

  describe '#remove_hyperlink' do
    it 'removes a specified hyperlink from submitted_hyperlinks' do
      team.submitted_hyperlinks = YAML.dump(['https://example.com', 'https://another.com'])
      team.remove_hyperlink('https://example.com')
      expect(team.hyperlinks).not_to include('https://example.com')
    end
  end

  describe '#files' do
    it 'returns all file paths in a directory recursively' do
      Dir.mktmpdir do |dir|
        file1 = File.join(dir, 'test1.txt')
        file2 = File.join(dir, 'sub', 'test2.txt')
        File.write(file1, 'content')
        FileUtils.mkdir_p(File.dirname(file2))
        File.write(file2, 'content')

        expect(team.files(dir)).to include(file1, file2)
      end
    end

    it 'returns empty array if path is not a directory' do
      expect(team.files('/non/existent/path')).to eq([])
    end
  end

  describe '#team' do
    it 'returns the team for a given participant' do
      participant = AssignmentParticipant.create!(user: user, assignment_id: assignment.id, handle: 'handle')
      team = AssignmentTeam.create!(name: 'Team for Participant', assignment_id: assignment.id, parent_id: assignment.id)
      TeamsParticipant.create!(participant: participant, team: team)

      expect(AssignmentTeam.team(participant)).to eq(team)
    end

    it 'returns nil if participant is nil' do
      expect(AssignmentTeam.team(nil)).to be_nil
    end

    it 'returns nil if no matching team found' do
      other_assignment = Assignment.create!(title: 'Assignment 2', instructor: instructor, directory_path: 'path2')
      participant = AssignmentParticipant.create!(user: user, assignment_id: other_assignment.id, handle: 'handle')
      expect(AssignmentTeam.team(participant)).to be_nil
    end
  end
  
  describe '#export_fields' do
    it 'includes team name and assignment name by default' do
      expect(AssignmentTeam.export_fields({})).to eq(['Team Name', 'Assignment Name'])
    end
  
    it 'includes team members if team_name is false' do
      expect(AssignmentTeam.export_fields({ team_name: 'false' })).to eq(['Team Name', 'Team members', 'Assignment Name'])
    end
  end
  
  describe '#remove_team_by_id' do
    it 'removes the team if it exists' do
      new_team = AssignmentTeam.create!(name: 'To Delete', parent_id: assignment.id, assignment_id: assignment.id)
      expect {
        AssignmentTeam.remove_team_by_id(new_team.id)
      }.to change { AssignmentTeam.exists?(new_team.id) }.from(true).to(false)
    end
  end
  
  describe '#path' do
    it 'returns the correct team directory path' do
      team.update(directory_num: 5)
      expect(team.path).to eq(File.join(assignment.directory_path, '5'))
    end
  end

  describe '#set_team_directory_num' do
    it 'sets directory_num to 0 if no other teams exist' do
      other_team.destroy
      team.update!(directory_num: nil)
      team.set_team_directory_num
      expect(team.directory_num).to eq(0)
    end

    it 'increments directory_num from max existing value' do
      AssignmentTeam.create!(name: 'Existing Team', parent_id: assignment.id, assignment_id: assignment.id, directory_num: 5)
      team.update!(directory_num: nil)
      team.set_team_directory_num
      expect(team.directory_num).to eq(6)
    end

    it 'does not change directory_num if already set' do
      team.update!(directory_num: 3)
      expect { team.set_team_directory_num }.not_to change { team.directory_num }
    end
  end

  describe '#has_been_reviewed?' do
    it 'returns true if any ResponseMap exists for the team' do
      review_map = ReviewResponseMap.create!(
        reviewee: team,
        reviewer: participant_reviewer,
        reviewed_object_id: assignment.id
      )
      expect(team.has_been_reviewed?).to be true
    end

    it 'returns false if no ResponseMap exists for the team' do
      expect(team.has_been_reviewed?).to be false
    end
  end

  describe '#most_recent_submission' do
    it 'returns the most recently updated submission' do
      older = SubmissionRecord.create!(
        team_id: team.id,
        assignment_id: assignment.id,
        content: 'Old content',
        operation: 'create',
        user: user.name,
        updated_at: 2.days.ago
      )

      newer = SubmissionRecord.create!(
        team_id: team.id,
        assignment_id: assignment.id,
        content: 'New content',
        operation: 'update',
        user: user.name,
        updated_at: Time.now
      )
      expect(team.most_recent_submission).to eq(newer)
    end

    it 'returns nil if there are no submissions' do
      expect(team.most_recent_submission).to be_nil
    end
  end

  describe '#get_logged_in_reviewer_id' do
    it 'returns participant ID if user is part of the team' do
      expect(team.get_logged_in_reviewer_id(user.id)).to eq(participant.id)
    end

    it 'returns nil if user is not part of any participant' do
      expect(team.get_logged_in_reviewer_id(999)).to be_nil
    end
  end

  describe '#current_user_is_reviewer?' do
    it 'returns true if the current user is a participant in the team' do
      AssignmentParticipant.create!(user: user, assignment_id: assignment.id, handle: 'handle')
      expect(team.current_user_is_reviewer?(user.id)).to be true
    end

    it 'returns false if the current user is not a participant in the team' do
      other_user = User.create!(
        name: 'Other User',
        full_name: 'Other Full',
        email: 'other@example.com',
        password: 'password',
        role: role
      )
      expect(team.current_user_is_reviewer?(other_user.id)).to be false
    end
  end

  describe '#assign_team_to_topic' do
    it 'creates SignedUpTeam, TeamNode, and TeamUserNode records' do
      topic = SignUpTopic.create!(topic_identifier: 'T1', topic_name: 'Topic 1', assignment: assignment)

      expect {
        team.assign_team_to_topic(topic)
      }.to change { SignedUpTeam.count }.by(1)
      .and change { TeamNode.count }.by(1)
      .and change { TeamUserNode.count }.by(1)

      signed_up = SignedUpTeam.last
      expect(signed_up.sign_up_topic_id).to eq(topic.id)
      expect(signed_up.team_id).to eq(team.id)
      expect(signed_up.is_waitlisted).to eq(false)

      team_node = TeamNode.last
      expect(team_node.parent_id).to eq(topic.assignment_id)
      expect(team_node.node_object_id).to eq(team.id)

      team_user_node = TeamUserNode.last
      expect(team_user_node.parent_id).to eq(team_node.id)
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentParticipant, type: :model do
  # $redis = global variable
  before(:each) do
    $redis = double('Redis', get: nil)
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

  let(:assignment) do
    Assignment.create!(
      title: 'Test Assignment',
      directory_path: 'assignment/test',
      instructor: user
    )
  end

  let(:participant) do
    AssignmentParticipant.create!(
      user: user,
      assignment: assignment,
      handle: 'handle1'
    )
  end

  describe '#set_handle' do
    it 'uses user name if user handle is nil or blank' do
      user.update_column(:handle, nil)
      participant.update_column(:handle, nil)
      participant.set_handle
      expect(participant.handle).to eq(user.name)
    end

    it 'uses user handle if it is unique' do
      user.update_column(:handle, 'unique_handle')
      participant.update_column(:handle, nil)
      participant.set_handle
      expect(participant.handle).to eq('unique_handle')
    end

    it 'falls back to user name if handle already exists in assignment' do
      user.update_column(:handle, 'duplicate_handle')
      AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'duplicate_handle')
      participant.update_column(:handle, nil)
      participant.set_handle
      expect(participant.handle).to eq(user.name)
    end
  end

  describe '#reviewers' do
    it 'returns all the participants in this assignment who have reviewed the team where this participant belongs' do
      team = AssignmentTeam.create!(name: 'Team1', assignment: assignment)
      allow(participant).to receive(:team).and_return(team)

      response_map = instance_double('ReviewResponseMap', reviewer_id: participant.id)
      allow(ReviewResponseMap).to receive(:where).with(reviewee_id: team.id).and_return([response_map])
      allow(AssignmentParticipant).to receive(:find).with(participant.id).and_return(participant)

      expect(participant.reviewers.map(&:id)).to include(participant.id)
    end
  end


  describe '#copy_to_course' do
    it 'creates a new CourseParticipant if none exists' do
      institution = Institution.create!(name: 'I1')
      course = Course.create!(name: 'C1', directory_path: 'dir1', institution: institution, instructor: user)
      expect {
        participant.copy_to_course(course.id)
      }.to change { CourseParticipant.count }.by(1)
    end
  end

  describe '#verify_signature' do
    it 'compares derived public key with user public key' do
      key = OpenSSL::PKey::RSA.generate(2048)

      fake_user = double('User', public_key: key.public_key.to_pem)
      allow(participant).to receive(:user).and_return(fake_user)

      expect(participant.verify_signature(key.to_pem)).to eq(true)
    end
  end

  describe '#reviewer' do
    it 'returns self if team reviewing is off' do
      allow(assignment).to receive(:team_reviewing_enabled).and_return(false)
      expect(participant.reviewer).to eq(participant)
    end

    it 'returns team if team reviewing is on' do
      team = double('team')
      allow(participant).to receive(:team).and_return(team)
      allow(assignment).to receive(:team_reviewing_enabled).and_return(true)
      expect(participant.reviewer).to eq(team)
    end
  end

  describe '#directory_path' do
    it 'returns the directory path of the assignment' do
      expect(participant.directory_path).to eq('assignment/test')
    end
  end

  describe '#set_current_user' do
    it 'does nothing (stub)' do
      expect { participant.set_current_user(user) }.not_to raise_error
    end
  end

  describe '#feedback' do
    it 'calls assessments_for on FeedbackResponseMap' do
      dummy_class = Class.new do
        def self.assessments_for(arg); end
      end
      stub_const('FeedbackResponseMap', dummy_class)

      expect(FeedbackResponseMap).to receive(:assessments_for).with(participant)
      participant.feedback
    end
  end

  describe '#reviews' do
    it 'calls assessments_for on ReviewResponseMap for the team' do
      fake_team = double('Team')
      allow(participant).to receive(:team).and_return(fake_team)

      dummy_class = Class.new do
        def self.assessments_for(arg); end
      end
      stub_const('ReviewResponseMap', dummy_class)

      expect(ReviewResponseMap).to receive(:assessments_for).with(fake_team)
      participant.reviews
    end
  end

  describe '#logged_in_reviewer_id' do
    it 'returns its own ID' do
      expect(participant.logged_in_reviewer_id(user.id)).to eq(participant.id)
    end
  end

  describe '#current_user_is_reviewer?' do
    it 'returns true if user IDs match' do
      expect(participant.current_user_is_reviewer?(user.id)).to eq(true)
    end

    it 'returns false if user IDs do not match' do
      expect(participant.current_user_is_reviewer?(user.id + 1)).to eq(false)
    end
  end

  describe '#quizzes_taken' do
    it 'calls assessments_for on QuizResponseMap' do
      dummy_class = Class.new do
        def self.assessments_for(_arg); end
      end
      stub_const('QuizResponseMap', dummy_class)

      expect(QuizResponseMap).to receive(:assessments_for).with(participant)
      participant.quizzes_taken
    end
  end


  describe '#metareviews' do
    it 'calls assessments_for on MetareviewResponseMap' do
      dummy_class = Class.new do
        def self.assessments_for(_arg); end
      end
      stub_const('MetareviewResponseMap', dummy_class)

      expect(MetareviewResponseMap).to receive(:assessments_for).with(participant)
      participant.metareviews
    end
  end

  describe '#teammate_reviews' do
    it 'calls assessments_for on TeammateReviewResponseMap' do
      dummy_class = Class.new do
        def self.assessments_for(_arg); end
      end
      stub_const('TeammateReviewResponseMap', dummy_class)

      expect(TeammateReviewResponseMap).to receive(:assessments_for).with(participant)
      participant.teammate_reviews
    end
  end

  describe '#bookmark_reviews' do
    it 'calls assessments_for on BookmarkRatingResponseMap' do
      dummy_class = Class.new do
        def self.assessments_for(_arg); end
      end
      stub_const('BookmarkRatingResponseMap', dummy_class)

      expect(BookmarkRatingResponseMap).to receive(:assessments_for).with(participant)
      participant.bookmark_reviews
    end
  end

  describe '#files' do
    it 'returns an empty list for a non-existent directory' do
      expect(participant.files('non/existent')).to eq([])
    end
  end

  describe '#path' do
    it 'returns full path if assignment and team exist' do
      mock_team = double('Team', directory_num: 7)
      mock_assignment = double('Assignment', path: 'base/path')

      allow(participant).to receive(:assignment).and_return(mock_assignment)
      allow(participant).to receive(:team).and_return(mock_team)

      expect(participant.path).to eq('base/path/7')
    end
  end

  describe '#review_file_path' do
    it 'returns correct peer review path when team exists' do
      response_map = double('ResponseMap', reviewee_id: 5, reviewed_object_id: 10)
      allow(ResponseMap).to receive(:find).and_return(response_map)
      allow(TeamsParticipant).to receive(:find_by).and_return(double('TeamsParticipant', user_id: 3))

      team = double('Team', directory_num: 4)
      allow(Participant).to receive(:find_by).and_return(double('Participant', team: team))

      fake_assignment = double('Assignment', path: 'assignments/test')
      allow(participant).to receive(:assignment).and_return(fake_assignment)

      expect(participant.review_file_path(1)).to eq('assignments/test/4_review/1')
    end
  end

  # describe '#current_stage' do
  #   it 'delegates to assignment.current_stage' do
  #     allow(SignedUpTeam).to receive(:topic_id).and_return(5)
  #     allow(assignment).to receive(:current_stage).with(5)
  #     participant.current_stage
  #   end
  # end
  #
  # describe '#stage_deadline' do
  #   it 'returns stage name if not Finished' do
  #     allow(SignedUpTeam).to receive(:topic_id).and_return(3)
  #     allow(assignment).to receive(:stage_deadline).with(3).and_return('In progress')
  #     expect(participant.stage_deadline).to eq('In progress')
  #   end
  # end

  describe '#assign_copyright' do
    it 'raises if signature is invalid' do
      allow(participant).to receive(:verify_signature).and_return(false)
      expect {
        participant.assign_copyright('invalid')
      }.to raise_error('Invalid key')
    end
  end

  describe '.import' do
    let(:session) { { user: user } }

    it 'raises if no username is provided' do
      expect {
        described_class.import({}, nil, session: session, assignment_id: assignment.id)
      }.to raise_error(ArgumentError)
    end

    it 'raises if assignment not found' do
      expect {
        described_class.import({ username: user.name }, nil, session: session, assignment_id: -1)
      }.to raise_error(ImportError)
    end

    it 'creates a new AssignmentParticipant' do
      expect {
        described_class.import({ username: user.name }, nil, session: session, assignment_id: assignment.id)
      }.to change { AssignmentParticipant.count }.by(1)
    end

    it 'does not duplicate if participant already exists' do
      described_class.create!(user: user, assignment: assignment, handle: 'h')
      expect {
        described_class.import({ username: user.name }, nil, session: session, assignment_id: assignment.id)
      }.not_to change { AssignmentParticipant.count }
    end
  end
end

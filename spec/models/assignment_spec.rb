
require 'rails_helper'

RSpec.describe Assignment, type: :model do

  let(:team) {Team.new(id: 1)}
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }

  describe '.get_all_review_comments' do
    it 'returns concatenated review comments and # of reviews in each round' do
      allow(Assignment).to receive(:find).with(1).and_return(assignment)
      allow(assignment).to receive(:num_review_rounds).and_return(2)
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:response).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer])
      allow(response2).to receive(:scores).and_return([answer2])
      expect(assignment.get_all_review_comments(1)).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  # Get a collection of all comments across all rounds of a review as well as a count of the total number of comments. Returns the above
  # information both for totals and in a list per-round.
  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(assignment).to receive(:get_all_review_comments).with(1)
                                                                  .and_return([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
      expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
    end
  end

  describe '#participant_on_team?' do
    let!(:institution) { Institution.create!(name: "NC State") }
    let!(:student_role) { Role.create!(name: "Student") }
    let!(:instructor_role) { Role.create!(name: "Instructor") }

    let!(:instructor) do
      User.create!(
        name: "instructor",
        email: "instructor@example.com",
        password_digest: "password",
        full_name: "Instructor User",
        role: instructor_role,
        institution: institution
      )
    end

    let!(:user) do
      User.create!(
        name: 'testuser',
        email: 'testuser@example.com',
        password_digest: 'password',
        full_name: 'Test User',
        role: student_role,
        institution: institution
      )
    end

    let!(:assignment) { Assignment.create!(name: 'Test Assignment', instructor: instructor) }
    let!(:team) { Team.create!(assignment: assignment) }

    context 'when participant is already on a team for assignment' do
      it 'returns true' do
        participant = Participant.create!(user: user, assignment: assignment, handle: 'handle1')
        team.participants << participant  # explicitly add Participant to team

        expect(assignment.participant_on_team?(participant)).to eq(true)
      end
    end

    context 'when participant is not on any team for assignment' do
      it 'returns false' do
        participant = Participant.create!(user: user, assignment: assignment, handle: 'handle2')
        expect(assignment.participant_on_team?(participant)).to eq(false)
      end
    end
  end




  describe '#can_participant_join_team_for_assignment?' do
    let(:institution) { Institution.create!(name: "NC State") }
    let(:student_role) { Role.create!(name: "Student") }
    let(:instructor_role) { Role.create!(name: "Instructor") }

    let(:instructor) do
      User.create!(
        name: "instructor",
        email: "instructor@example.com",
        password_digest: "password",
        full_name: "Instructor User",
        role: instructor_role,
        institution: institution
      )
    end

    let(:user) do
      User.create!(
        name: 'testuser',
        email: 'testuser@example.com',
        password_digest: 'password',
        full_name: 'Test User',
        role: student_role,
        institution: institution
      )
    end

    let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor: instructor) }

    context 'when participant is already on a team for the assignment' do
      it 'returns an error message indicating the participant is already assigned' do
        allow(assignment).to receive(:participant_on_team?).with(user).and_return(true)
        result = assignment.can_participant_join_team_for_assignment?(user, assignment.id)
        expect(result).to eq({ success: false, error: "This user is already assigned to a team for this assignment" })
      end
    end

    context 'when participant is not registered as a participant for the assignment' do
      it 'returns an error message indicating the participant is not registered' do
        allow(assignment).to receive(:participant_on_team?).with(user).and_return(false)
        allow(AssignmentParticipant).to receive(:find_by).with(user_id: user.id, assignment_id: assignment.id).and_return(nil)
        result = assignment.can_participant_join_team_for_assignment?(user, assignment.id)
        expect(result).to eq({ success: false, error: "testuser is not a participant in this assignment" })
      end
    end

    context 'when participant is eligible to join a team for the assignment' do
      it 'returns success true' do
        participant = AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'handle')
        allow(assignment).to receive(:participant_on_team?).with(user).and_return(false)
        allow(AssignmentParticipant).to receive(:find_by).with(user_id: user.id, assignment_id: assignment.id).and_return(participant)

        result = assignment.can_participant_join_team_for_assignment?(user, assignment.id)
        expect(result).to eq({ success: true })
      end
    end
  end




end

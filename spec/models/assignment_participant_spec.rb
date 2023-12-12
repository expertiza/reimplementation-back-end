require "rails_helper"

describe 'AssignmentParticipant' do
    let(:response) { build(:response) }
    let(:team) { build(:assignment_team, id: 1) }
    let(:team2) { build(:assignment_team, id: 2) }
    let(:response_map) { build(:review_response_map, reviewer_id: 2, response: [response]) }
    let(:participant) { build(:participant, id: 1, assignment: assignment, handle: nil ) }
    let(:participant2) { build(:participant, id: 2, grade: 100) }
    let(:assignment) { build(:assignment, id: 1) }
    let(:question) { double('Question') }



    describe '#dir_path' do
      it 'returns the directory path of current assignment' do
        # Assertion to check if the participant's dir_path method returns 'final_test'
        expect(participant.dir_path).to eq('final_test')
      end
    end


    describe '#get_reviewer' do
      context 'when the associated assignment is reviewed by his team' do
        it 'returns the team' do
          # Allowing the assignment to have team reviewing enabled
          allow(assignment).to receive(:team_reviewing_enabled).and_return(true)
          # Allowing the participant to belong to a specific team
          allow(participant).to receive(:team).and_return(team)
          # Expectation that calling get_reviewer on the participant will return the team
          expect(participant.get_reviewer).to eq(team)
        end
      end
    end


    describe '#path' do
      it 'returns the path name of the associated assignment submission for the team' do
        # Stubbing the 'path' method of the 'assignment' object to return 'assignment780'
        allow(assignment).to receive(:path).and_return('assignment780')
        # Stubbing the 'team' method of the 'participant' object to return 'team'
        allow(participant).to receive(:team).and_return(team)
        # Stubbing the 'directory_num' method of the 'team' object to return 780
        allow(team).to receive(:directory_num).and_return(780)
        # Expecting the 'path' method of 'participant' to return 'assignment780/780'
        expect(participant.path).to eq('assignment780/780')
      end
    end

    describe '#feedback' do
      it 'returns corresponding author feedback responses given by current participant' do
        # Stubbing the 'assessments_for' method of FeedbackResponseMap to return a single response for the 'participant'.
        allow(FeedbackResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        # Expects that calling 'participant.feedback' will return an array containing the 'response'.
        expect(participant.feedback).to eq([response])
      end
    end

    describe '#reviews' do
      it 'returns corresponding peer review responses given by current team' do
        # Ensure the participant is associated with the team
        allow(participant).to receive(:team).and_return(team)
        # Stubbing ReviewResponseMap's 'assessments_for' method to return a specific response associated with the team
        allow(ReviewResponseMap).to receive(:assessments_for).with(team).and_return([response])
        # Expect the 'participant.reviews' method to return an array containing the specified 'response'
        expect(participant.reviews).to eq([response])
      end
    end

    describe '#quizzes_taken' do
      it 'returns corresponding quiz responses given by current participant' do
        # Stub the behavior of QuizResponseMap's assessments_for method
        # to return an array containing a mock 'response' for the 'participant'
        allow(QuizResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        # Expect the result of participant.quizzes_taken to be equal to [response]
        expect(participant.quizzes_taken).to eq([response])
      end
    end

    describe '#metareviews' do
      it 'returns corresponding metareview responses given by current participant' do
        # Stubbing the 'assessments_for' method of MetareviewResponseMap with a participant and returning a mocked response
        allow(MetareviewResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        # Expecting that calling 'participant.metareviews' will return an array containing the mocked response
        expect(participant.metareviews).to eq([response])
      end
    end

    describe '#teammate_reviews' do
      it 'returns corresponding teammate review responses given by current participant' do
        # Stubbing the 'assessments_for' method of TeammateReviewResponseMap
        # to return a specific response for the participant
        allow(TeammateReviewResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        # Expectation: participant's 'teammate_reviews' should return the given response
        expect(participant.teammate_reviews).to eq([response])
      end
    end

    describe '#bookmark_reviews' do
      it 'returns corresponding bookmark review responses given by current participant' do
        # Stub/mock the behavior of 'BookmarkRatingResponseMap.assessments_for' to return a specific response for a participant
        allow(BookmarkRatingResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        # Expect that the 'participant.bookmark_reviews' method will return the mocked response
        expect(participant.bookmark_reviews).to eq([response])
      end
    end
 end

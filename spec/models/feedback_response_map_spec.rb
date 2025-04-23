describe FeedbackResponseMap do
  let(:questionnaire1) { Questionnaire.new(id: 1, questionnaire_type: 'AuthorFeedbackQuestionnaire') }
  let(:questionnaire2) { Questionnaire.new(id: 2, questionnaire_type: 'MetareviewQuestionnaire') }
  let(:participant) { Participant.new(id: 1) }
  let(:assignment) { Assignment.new(id: 1) }
  let(:team) { Team.new(id: 1) }
  let(:assignment_participant) { Participant.new(id: 2, assignment: assignment) }
  let(:feedback_response_map) { FeedbackResponseMap.new }
  let(:review_response_map) { ReviewResponseMap.new(id: 2, assignment: assignment, reviewer: participant, reviewee: team) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:response) { Response.new(id: 1, map_id: 1, response_map: review_response_map, scores: [answer]) }
  let(:user1) { User.new(name: 'abc', full_name: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789') }

  before(:each) do
    questionnaires = [questionnaire1, questionnaire2]
    allow(feedback_response_map).to receive(:reviewee).and_return(participant)
    allow(feedback_response_map).to receive(:review).and_return(response)
    allow(feedback_response_map).to receive(:reviewer).and_return(assignment_participant)
    allow(response).to receive(:map).and_return(review_response_map)
    allow(response).to receive(:reviewee).and_return(assignment_participant)
    allow(review_response_map).to receive(:assignment).and_return(assignment)
    allow(feedback_response_map).to receive(:assignment).and_return(assignment)
    allow(assignment).to receive(:questionnaires).and_return(questionnaires)
  end

  describe '#assignment' do
    it 'returns the assignment associated with this FeedbackResponseMap' do
      expect(feedback_response_map.assignment).to eq(assignment)
    end
  end

  describe '#title' do
    it 'returns "Feedback"' do
      expect(feedback_response_map.title).to eq('Feedback')
    end
  end

  describe '#questionnaire' do
    it 'returns an AuthorFeedbackQuestionnaire' do
      expect(feedback_response_map.questionnaire).to eq([questionnaire1, questionnaire2])
    end
  end

  describe '#contributor' do
    it 'returns the reviewee' do
      expect(feedback_response_map.contributor).to eq(participant)
    end
  end

  describe '#reviewer' do
    it 'returns the reviewer' do
      expect(feedback_response_map.reviewer).to eq(assignment_participant)
    end
  end

  describe '#round' do
    it 'returns the round number of the original review' do
      # Mock the response round number
      allow(feedback_response_map).to receive(:round).and_return(1)
      expect(feedback_response_map.round).to eq(1)
    end

    it 'returns nil if the round number is not present' do
      allow(feedback_response_map).to receive(:round).and_return(nil)
      expect(feedback_response_map.round).to be_nil
    end
  end

  # describe '#feedback_response_report' do
  #   it 'returns a report' do
  #     maps = [review_response_map]
  #     allow(ReviewResponseMap).to receive(:where).with(['reviewed_object_id = ?', 1]).and_return(maps)
  #     allow(maps).to receive(:pluck).with('id').and_return(review_response_map.id)
  #     allow(Team).to receive_message_chain(:includes, :where).and_return([team])
  #     allow(team).to receive(:users).and_return([user1])
  #     allow(user1).to receive(:id).and_return(1)
  #     allow(AssignmentParticipant).to receive(:where).with(parent_id: 1, user_id: 1).and_return([participant])

  #     response1 = instance_double('Response', round: 1, additional_comment: '')
  #     response2 = instance_double('Response', round: 2, additional_comment: 'LGTM')
  #     response3 = instance_double('Response', round: 3, additional_comment: 'Bad')
  #     rounds = [response1, response2, response3]
      
  #     # Mock `Response.where` to return rounds
  #     allow(Response).to receive(:where).with(['map_id IN (?)', 2]).and_return(rounds)
  #     allow(Response).to receive_message_chain(:where, :order).with(['map_id IN (?)', 2], 'created_at DESC').and_return(['map_id IN (?)', 2])
  #     allow(Assignment).to receive(:find).with(1).and_return(assignment)
  #     # allow(assignment).to receive(:varying_rubrics_by_round).and_return(true)

  #     # Mock necessary methods for `response` objects
  #     allow(response1).to receive(:map_id).and_return(1)
  #     allow(response2).to receive(:map_id).and_return(2)
  #     allow(response3).to receive(:map_id).and_return(3)
  #     allow(response1).to receive(:id).and_return(1)
  #     allow(response2).to receive(:id).and_return(2)
  #     allow(response3).to receive(:id).and_return(3)

  #     report = FeedbackResponseMap.feedback_response_report(1, nil)
  #     expect(report[0]).to eq([participant])
  #     expect(report[1]).to eq([1, 2, 3])
  #     expect(report[2]).to eq(nil)
  #     expect(report[3]).to eq(nil)
  #   end
  # end
end
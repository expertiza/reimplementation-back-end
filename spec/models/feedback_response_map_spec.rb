describe FeedbackResponseMap do
    let(:questionnaire1) { Questionnaire.new(id: 1, questionnaire_type: 'AuthorFeedbackQuestionnaire') }
    let(:questionnaire2) { Questionnaire.new(id: 2, questionnaire_type: 'MetareviewQuestionnaire') }
    let(:participant) { Participant.new(id: 1) }
    let(:assignment) { Assignment.new(id: 1) }
    let(:team) { Team.new(assignment_id: assignment.id) }
    let(:assignment_participant) { Participant.new(id: 2, assignment: assignment) }
    let(:feedback_response_map) { FeedbackResponseMap.new }
    let(:review_response_map) { ReviewResponseMap.new(id: 2, assignment: assignment, reviewer: participant, reviewee: team) }
    let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
    let(:response) { Response.new(id: 1, map_id: 1, response_map: review_response_map, scores: [answer]) }
    let(:user1) { User.new(name: 'abc', fullname: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789') }
  
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
    #   allow(questionnaires).to receive(:find_by).with(questionnaire_type: 'AuthorFeedbackQuestionnaire').and_return([questionnaire1])
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
        # Assuming `feedback_response_map.questionnaire` returns the actual questionnaire object
        expect(feedback_response_map.questionnaire).to eq([questionnaire1, questionnaire2])
      end
    end
  end
  
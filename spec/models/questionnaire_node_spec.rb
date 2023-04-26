require "rails_helper"

describe QuestionnaireNode do
  let(:questionnaire) { FactoryBot.build(:questionnaire) }
  let(:questionnaire2) { FactoryBot.build(:questionnaire) }
  let(:questionnaire3) { FactoryBot.build(:questionnaire) }
  let(:questionnaire_node) { FactoryBot.build(:questionnaire_node) }
  let(:teaching_assistant) { FactoryBot.build(:teaching_assistant) }
   let(:student) { User.new name: 'abc', fullname: 'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789' }
  let(:assignment) { FactoryBot.build(:assignment, id: 1, name: 'Assignment') }
  
  describe '#leaf' do
    it 'returns whether the node is a leaf' do
      expect(QuestionnaireNode.leaf?).to eq(true)
    end
  end
  describe '#get_modified_date' do
    it 'returns when the questionnaire was last changed' do
      allow(Questionnaire).to receive(:find_by).with(id: 0).and_return(questionnaire)
      allow(questionnaire).to receive(:updated_at).and_return('2011-11-11 11:11:11')
      expect(questionnaire_node.modified_date).to eq('2011-11-11 11:11:11')
    end
  end
  describe '#get_creation_date' do
    it 'returns when the questionnaire was created' do
      allow(Questionnaire).to receive(:find_by).with(id: 0).and_return(questionnaire)
      allow(questionnaire).to receive(:created_at).and_return('2011-11-11 11:11:11')
      expect(questionnaire_node.creation_date).to eq('2011-11-11 11:11:11')
    end
  end
  describe '#get_private' do
    it 'returns whether the associated questionnaire is private' do
      allow(Questionnaire).to receive(:find_by).with(id: 0).and_return(questionnaire)
      allow(questionnaire).to receive(:private).and_return(true)
      expect(questionnaire_node.private?).to eq(true)
    end
  end
  describe '#get_instructor_id' do
    it 'returns whether the associated instructor id with the questionnaire' do
      allow(Questionnaire).to receive(:find_by).with(id: 0).and_return(questionnaire)
      allow(questionnaire).to receive(:instructor_id).and_return(1)
      expect(questionnaire_node.instructor_id).to eq(1)
    end
  end
  describe '#get_name' do
    it 'returns questionnaire name' do
      allow(Questionnaire).to receive(:find_by).with(id: 0).and_return(questionnaire)
      allow(questionnaire).to receive(:name).and_return('CSC 517 Assignment 1')
      expect(questionnaire_node.name).to eq('CSC 517 Assignment 1')
    end
  end
  
end

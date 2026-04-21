
require 'rails_helper'
describe Questionnaire, type: :model do

    before do
        allow_any_instance_of(User).to receive(:set_defaults)
    end
    let(:instructor) { create(:instructor) }
    let(:questionnaire) do
            create(:questionnaire,
            name: 'abc',
            private: false,
            min_question_score: 0,
            max_question_score: 10,
            instructor: instructor)
    end

    let(:question1) do
        create(:item, questionnaire: questionnaire, weight: 1, seq: 1, txt: 'que 1', question_type: 'scale')
    end
    let(:question2) do
        create(:item, questionnaire: questionnaire, weight: 10, seq: 2, txt: 'que 2', question_type: 'multiple_choice')
    end

    let(:question_advice1) do
        create(:question_advice, question_id: question1.id)
    end

    let(:question_advice2) do
        create(:question_advice, question_id: question2.id, advice: 'advice for question 2', score: 6)
    end

    let(:question_advice3) do
        create(:question_advice, question_id: question1.id, advice: 'advice for question 3', score: 1)
    end

    describe '#question association' do
        it 'returns the associated question of QuestionAdvice' do
            expect(question_advice1.question_id).to eq(question1.id)
            expect(question_advice2.question_id).to eq(question2.id)
            expect(question_advice3.question_id).to eq(question1.id)
        end

    end

    describe '#score' do
        it 'returns the score of QuestionAdvice' do
            expect(question_advice1.score).to eq(5)
            expect(question_advice2.score).to eq(6)
            expect(question_advice3.score).to eq(1)
        end
        
    end

    describe '#advice' do
        it 'returns the score of QuestionAdvice' do
            expect(question_advice1.advice).to eq('default advice')
            expect(question_advice2.advice).to eq('advice for question 2')
            expect(question_advice3.advice).to eq('advice for question 3')
        end
        
    end

    describe '#test export_fields' do
        it 'make sure that the columns of QuestionAdvice are properly being mapped' do
            output = QuestionAdvice.export_fields(options = {})
            expect(output).to eq(["id", "question_id", "score", "advice", "created_at", "updated_at"])
        end
    end

    describe '#test export' do
        it 'test the export method to see if values are being properly stored ' do
            csv = []
            
            expect(question1.questionnaire).to eq(questionnaire)
            expect(question2.questionnaire).to eq(questionnaire)
            
            expect(question_advice1.advice).to eq('default advice')
            expect(question_advice2.advice).to eq('advice for question 2')
            expect(question_advice3.advice).to eq('advice for question 3')


            QuestionAdvice.export(csv, questionnaire.id, nil)

            expect(csv.length).to eq(3)
        end
    end

    describe '#test to_json_by_question_id' do
        it 'verify json output with QuestionAdvice entries associated with question 1' do
            
            #instantiate the question_advice table 
            expect(question_advice1.question_id).to eq(question1.id)
            expect(question_advice3.question_id).to eq(question1.id)

            output = QuestionAdvice.where(question_id: question1.id).first


            expect(output.question_id).to eq(question1.id)

            output1 = QuestionAdvice.to_json_by_question_id(question1.id)

            expect(output1).to eq([
                { score: 5, advice: 'default advice' },
                { score: 1, advice: 'advice for question 3' }
            ])
        end 
        
        it 'verify json output with QuestionAdvice entries associated with question 2' do
            expect(question_advice2.question_id).to eq(question2.id)

            output = QuestionAdvice.to_json_by_question_id(question2.id)

            expect(output).to eq([
                { score: 6, advice: 'advice for question 2'}
            ])
        end 
        
    end
end
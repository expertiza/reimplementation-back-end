describe FindResourceService do
    describe '.call' do
        let(:instructor) { create(:instructor) }
        let(:assignment) { create(:assignment, instructor_id: instructor.id) }
        let(:quiz) do
        create(:questionnaire, name: "Quiz One", instructor_id: instructor.id,
                                min_question_score: 0, max_question_score: 10)
        end
    
        it "returns a quiz" do
        quiz = FindResourceService.call(Questionnaire, quiz.id)
        expect(quiz).to be_a(Questionnaire)
        expect(quiz.name).to eq("Quiz One")
        end
    
        it "returns an assignment" do
        assignment = FindResourceService.call(Assignment, assignment.id)
        expect(assignment).to be_a(Assignment)
        expect(assignment.name).to eq("Test Assignment")
        end
    
        it "returns nil when resource is not found" do
        quiz = FindResourceService.call(Questionnaire, 999)
        expect(quiz).to be_nil
        end
    end
end
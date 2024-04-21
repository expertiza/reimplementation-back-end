require 'rails_helper'
require 'questionnaire_helper'

describe AdviceController, type: :controller do
  let(:super_admin) { build(:superadmin, id: 1, role_id: 1) }
  let(:instructor1) { build(:instructor, id: 10, role_id: 3, parent_id: 3, name: 'Instructor1') }
  let(:student1) { build(:student, id: 21, role_id: 5) }

  describe '#action_allowed?' do
    context 'when the role of current user is Super-Admin' do
      # Checking for Super-Admin
      it 'allows certain action' do
        stub_current_user(super_admin, super_admin.role.name, super_admin.role)
        expect(controller.send(:action_allowed?)).to be_truthy
      end
    end
    context 'when the role of current user is Instructor' do
      # Checking for Instructor
      it 'allows certain action' do
        stub_current_user(instructor1, instructor1.role.name, instructor1.role)
        expect(controller.send(:action_allowed?)).to be_truthy
      end
    end
    context 'when the role of current user is Student' do
      # Checking for Student
      it 'refuses certain action' do
        stub_current_user(student1, student1.role.name, student1.role)
        expect(controller.send(:action_allowed?)).to be_falsey
      end
    end
  end

  describe "#invalid_advice?" do
  let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1) }
  let(:questionAdvice2) { build(:question_advice, id: 2, score: 3, question_id: 1) }
  let(:questionnaire) do
    build(:questionnaire, id: 1, min_question_score: 1,
      questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
  end
    context "when the sorted advice is empty" do
      it "returns true" do
        ## Set sorted advice to empty.
        sorted_advice = []
        num_advices = 5
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to be_truthy
      end
    end

    context "when the number of advices does not match the expected number" do
      it "returns true" do
        ## Set sorted advice to be different length the num_advices.
        sorted_advice = [questionAdvice1, questionAdvice2]
        num_advices = 1
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to be_truthy
      end
    end

    context "when the highest scoring advice does not have the maximum question score" do
      it "returns true" do
        # Create a question advice with a score lower than the maximum question score
        questionAdvice1 = build(:question_advice, id: 1, score: 3, question_id: 1)
        questionnaire = build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1])], max_question_score: 5)

        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        sorted_advice = questionnaire.questions[0].question_advices.sort_by(&:score).reverse
    
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to be_truthy
      end
    end
    

    context "when the lowest scoring advice does not have the minimum question score" do
      it "returns true" do
        # Create a question advice with a score higher than the minimum question score
        questionAdvice1 = build(:question_advice, id: 1, score: 1, question_id: 1) # Assuming minimum question score is 2
        questionnaire = build(:questionnaire, id: 1, min_question_score: 2,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1])], max_question_score: 5)
    
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        sorted_advice = questionnaire.questions[0].question_advices.sort_by(&:score).reverse
    
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to be_truthy
      end
    end

    context 'when invalid_advice? is called with all conditions satisfied' do
      # Question Advices passing all conditions
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'invalid_advice? returns false when called with all correct pre-conditions ' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(false)
      end
    end
    
    
    
  end

  ########################################################################################
  ### These are the old invalid_advice tests. Waiting for Anuj to give feedback on what to do with these.
  describe '#invalid_advice?' do
    context 'when invalid_advice? is called with question advice score > max score of questionnaire' do
      # max score of advice = 3 (!=2)
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 3, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'invalid_advice? returns true when called with incorrect maximum score for a question advice' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(true)
      end
    end

    context 'when invalid_advice? is called with question advice score < min score of questionnaire' do
      # min score of advice = 0 (!=1)
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 0, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'invalid_advice? returns true when called with incorrect minimum score for a question advice' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(true)
      end
    end

    context 'when invalid_advice? is called with number of advices > (max-min) score of questionnaire' do
      # number of advices > 2
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionAdvice3) { build(:question_advice, id: 3, score: 2, question_id: 1, advice: 'Advice3') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2, questionAdvice3])], max_question_score: 2)
      end

      it 'invalid_advice? returns true when called with incorrect number of question advices' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(true)
      end
    end

    context 'when invalid_advice? is called with no advices for a question in questionnaire' do
      # 0 advices - empty list scenario
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [])], max_question_score: 2)
      end

      it 'invalid_advice? returns true when called with an empty advice list ' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(true)
      end
    end

    context 'when invalid_advice? is called with all conditions satisfied' do
      # Question Advices passing all conditions
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
                              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'invalid_advice? returns false when called with all correct pre-conditions ' do
        sorted_advice = questionnaire.questions[0].question_advices.sort_by { |x| x.score }.reverse
        num_advices = questionnaire.max_question_score - questionnaire.min_question_score + 1
        controller.instance_variable_set(:@questionnaire, questionnaire)
        expect(controller.invalid_advice?(sorted_advice, num_advices, questionnaire.questions[0])).to eq(false)
      end
    end
  end

  ########################################################################################


  describe '#edit_advice' do

    context 'when edit_advice is called and invalid_advice? evaluates to true' do
      # edit advice called
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'edit advice redirects correctly when called' do
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        params = { id: 1 }
        session = { user: instructor1 }
        result = get(:edit_advice, params:, session:)
        expect(result.status).to eq 200
        expect(result).to render_template(:edit_advice)
      end
    end

    context 'when advice adjustment is not necessary' do
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      it 'does not adjust advice size when called' do
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(controller).to receive(:invalid_advice?).and_return(false)
        expect(QuestionnaireHelper).not_to receive(:adjust_advice_size)
        get :edit_advice, params: { id: 1 }
      end
    end
    context "when the advice size needs adjustment" do
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      before do
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(controller).to receive(:invalid_advice?).and_return(true)
      end

      it "calculates the number of advices for each question" do
        expect(controller).to receive(:calculate_num_advices).once # Assuming there are two questions in the questionnaire
        get :edit_advice, params: { id: 1 }
      end

      it "sorts question advices in descending order by score" do
        expect(controller).to receive(:sort_question_advices).once # Assuming there are two questions in the questionnaire
        get :edit_advice, params: { id: 1 }
      end

      it "adjusts the advice size if the number of advices is less than the max score of the questionnaire" do
        allow(controller).to receive(:calculate_num_advices).and_return(1) # Assuming only one advice calculated
        expect(QuestionnaireHelper).to receive(:adjust_advice_size).with(questionnaire, questionnaire.questions.first)
        get :edit_advice, params: { id: 1 }
      end

      it "adjusts the advice size if the number of advices is greater than the max score of the questionnaire" do
        allow(controller).to receive(:calculate_num_advices).and_return(3) # Assuming three advices calculated
        expect(QuestionnaireHelper).to receive(:adjust_advice_size).with(questionnaire, questionnaire.questions.first)
        get :edit_advice, params: { id: 1 }
      end

      it "adjusts the advice size if the max score of the advices does not correspond to the max score of the questionnaire" do
        allow(controller).to receive(:sort_question_advices).and_return([questionAdvice2, questionAdvice1]) # Assuming advices not sorted correctly
        expect(QuestionnaireHelper).to receive(:adjust_advice_size).with(questionnaire, questionnaire.questions.first)
        get :edit_advice, params: { id: 1 }
      end

      it "adjusts the advice size if the min score of the advices does not correspond to the min score of the questionnaire" do
        allow(questionnaire).to receive(:min_question_score).and_return(0) # Assuming min score not matching
        expect(QuestionnaireHelper).to receive(:adjust_advice_size).with(questionnaire, questionnaire.questions.first)
        get :edit_advice, params: { id: 1 }
      end
    end

    context "when the advice size does not need adjustment" do
      let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
      let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
      let(:questionnaire) do
        build(:questionnaire, id: 1, min_question_score: 1,
              questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
      end

      before do
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(controller).to receive(:invalid_advice?).and_return(false)
      end

      it "does not adjust the advice size if the number of advices is equal to the max score of the questionnaire" do
        allow(controller).to receive(:calculate_num_advices).and_return(2) # Assuming two advices calculated
        expect(QuestionnaireHelper).not_to receive(:adjust_advice_size)
        get :edit_advice, params: { id: 1 }
      end

      it "does not adjust the advice size if the max score of the advices corresponds to the max score of the questionnaire" do
        expect(QuestionnaireHelper).not_to receive(:adjust_advice_size)
        get :edit_advice, params: { id: 1 }
      end

      it "does not adjust the advice size if the min score of the advices corresponds to the min score of the questionnaire" do
        expect(QuestionnaireHelper).not_to receive(:adjust_advice_size)
        get :edit_advice, params: { id: 1 }
      end
    end
  end

  describe '#save_advice' do
    let(:questionAdvice1) { build(:question_advice, id: 1, score: 1, question_id: 1, advice: 'Advice1') }
    let(:questionAdvice2) { build(:question_advice, id: 2, score: 2, question_id: 1, advice: 'Advice2') }
    let(:questionnaire) do
      build(:questionnaire, id: 1, min_question_score: 1,
            questions: [build(:question, id: 1, weight: 2, question_advices: [questionAdvice1, questionAdvice2])], max_question_score: 2)
    end
    context 'when the advice is present' do
      it 'updates the advice for each key' do
        # Arrange
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(QuestionAdvice).to receive(:update).with('1', { advice: 'Hello' }).and_return('Ok')
        allow(QuestionAdvice).to receive(:update).with('2', { advice: 'Goodbye' }).and_return('Ok')
        # Add some advice parameters that will allow for update success
        advice_params = {
          '1' => { advice: 'Hello' },
          '2' => { advice: 'Goodbye' }
        }
        params = { advice: advice_params, id: 1 }
        session = { user: instructor1 }

        # Act
        result = get(:save_advice, params:, session:)

        # Assert
        # check each key to see if it received update
        # Always expect redirect
        advice_params.keys.each do |advice_key|
          expect(QuestionAdvice).to have_received(:update).with(advice_key, advice: advice_params[advice_key][:advice])
        end
        expect(result.status).to eq 302
        expect(result).to redirect_to('/advice/edit_advice?id=1')
      end

      it 'sets a success flash notice' do
        # Arrange
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(QuestionAdvice).to receive(:update).with('1', { advice: 'Hello' }).and_return('Ok')
        allow(QuestionAdvice).to receive(:update).with('2', { advice: 'Goodbye' }).and_return('Ok')
        # Add some advice parameters that will allow for update success
        params = { advice: {
          '1' => { advice: 'Hello' },
          '2' => { advice: 'Goodbye' }
        }, id: 1 }
        session = { user: instructor1 }

        # Act
        get(:save_advice, params:, session:)

        # Assert
        expect(flash[:notice]).to eq('The advice was successfully saved!')
      end
    end

    context 'when the advice is not present' do
      it 'does not update any advice' do
        # Arrange
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(QuestionAdvice).to receive(:update).with(any_args).and_return('Ok')
        # no advice parameter
        params = { id: 1 }
        session = { user: instructor1 }

        # Act
        result = get(:save_advice, params:, session:)

        # Assert
        # Expect no update to be called with nil params for advice
        # Expect no flash
        # Always expect redirect
        expect(QuestionAdvice).not_to have_received(:update)
        expect(flash[:notice]).not_to be_present
        expect(result.status).to eq 302
        expect(result).to redirect_to('/advice/edit_advice?id=1')
      end
    end

    context 'when the questionnaire is not found' do
      it 'renders the edit_advice view' do
        # Arrange
        allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
        allow(QuestionAdvice).to receive(:update).with(any_args).and_raise(ActiveRecord::RecordNotFound)

        #Act
        # call get on edit_advice with params that will hit the record not found path
        get :edit_advice, params: { advice: {
          '1' => { advice: 'Hello' },
          '2' => { advice: 'Goodbye' }
        }, id: 1 }

        # Assert: Verify that the controller renders the correct view
        expect(response).to render_template('edit_advice')
      end
    end

    it 'redirects to the edit_advice action' do
      # Arrange
      allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
      allow(QuestionAdvice).to receive(:update).with(any_args).and_return('Ok')
      params = { advice: {
        '1' => { advice: 'Hello' },
        '2' => { advice: 'Goodbye' }
      }, id: 1 }
      session = { user: instructor1 }

      # Act
      result = get(:save_advice, params:, session:)

      # Assert
      # expect 302 redirect and for it to redirect to edit_advice
      expect(result.status).to eq 302
      expect(result).to redirect_to('/advice/edit_advice?id=1')
    end
  end
end
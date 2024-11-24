class Dropdown < UnscoredQuestion
    include QuestionHelper
  
    attr_accessor :txt, :type, :count, :weight
    def edit(count)
      edit_common("Question #{count}:", txt , weight, type).to_json
    end
  
    def view_question_text
      view_question_text_common(txt, type, weight, 'N/A').to_json
    end
  
    def complete(count, answer = nil)
      options = (1..count).map { |option| { value: option, selected: (option == answer.to_i) } }
      { dropdown_options: options }.to_json
    end
  
    def complete_for_alternatives(alternatives, answer)
      options = alternatives.map { |alt| { value: alt, selected: (alt == answer) } }
      { dropdown_options: options }.to_json
    end
  
    def view_completed_question
      { selected_option: (count && answer) ? "#{answer} (out of #{count})" : 'Question not answered.' }.to_json
    end
  end
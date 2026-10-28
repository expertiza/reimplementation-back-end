# frozen_string_literal: true

module QuestionHelper
    def edit_common(label = nil, min_item_score = nil, max_item_score = nil, txt, weight, type)
      {
        form: true,
        label: label,
        input_type: 'text',
        input_name: 'item',
        input_value: txt,
        min_item_score: min_item_score,
        max_item_score: max_item_score,
        weight: weight,
        type: type
      }
    end
  
    def view_item_text_common(text, type, weight, score_range)
      { text: text, type: type, weight: weight, score_range: score_range }
    end
  end
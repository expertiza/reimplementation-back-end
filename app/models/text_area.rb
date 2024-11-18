class TextArea < Question
    def complete(count,answer = nil)
      {
        action: 'complete',
        data: {
          count: count,
          comment: answer&.comments,
          size: size || '70,1', # Assuming '70,1' is the default size
        }
      }.to_json
    end
  
    def view_completed_question(count, answer)
      {
        action: 'view_completed_question',
        data: {
          count: count,
          comment: answer.comments
        }
      }.to_json
    end
  end
class TextField < Question
    validates :size, presence: true
  
    def complete(count, answer = nil)
      {
        action: 'complete',
        data: {
          label: "Question ##{count}",
          type: 'text',
          name: "response[answers][#{id}]",
          id: "responses_#{id}",
          value: answer&.comments
        }
      }.to_json
    end
  
    def view_completed_question(count, files)
      if question_type == 'TextField' && break_before
        {
          action: 'view_completed_question',
          data: {
            type: 'text',
            label: "Completed Question ##{count}",
            value: txt,
            break_before: break_before
          }
        }.to_json
      else
        {
          action: 'view_completed_question',
          data: {
            type: 'text',
            label: "Completed Question ##{count}",
            value: txt,
            break_before: break_before
          }
        }.to_json
      end
    end
  end
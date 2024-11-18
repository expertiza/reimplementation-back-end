class TextResponse < Question
    validates :size, presence: true
  
    def edit(_count)
      {
        action: 'edit',
        elements: [
          {
            type: 'link',
            text: 'Remove',
            href: "/questions/#{id}",
            method: 'delete'
          },
          {
            type: 'input',
            input_type: 'text',
            size: 6,
            name: "question[#{id}][seq]",
            id: "question_#{id}_seq",
            value: seq.to_s
          },
          {
            type: 'textarea',
            cols: 50,
            rows: 1,
            name: "question[#{id}][txt]",
            id: "question_#{id}_txt",
            placeholder: 'Edit question content here',
            value: txt
          },
          {
            type: 'input',
            input_type: 'text',
            size: 10,
            name: "question[#{id}][question_type]",
            id: "question_#{id}_question_type",
            value: question_type,
            disabled: true
          },
          {
            type: 'input',
            input_type: 'text',
            size: 6,
            name: "question[#{id}][size]",
            id: "question_#{id}_size",
            value: size,
            label: 'Text area size'
          }
        ]
      }.to_json
    end
  
    def view_question_text
      {
        action: 'view_question_text',
        elements: [
          { type: 'text', value: txt },
          { type: 'text', value: question_type },
          { type: 'text', value: weight.to_s },
          { type: 'text', value: '—' }
        ]
      }.to_json
    end
  end
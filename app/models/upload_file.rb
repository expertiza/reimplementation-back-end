# app/models/upload_file.rb
class UploadFile < Question
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
            name: "question[#{id}][seq]",
            id: "question_#{id}_seq",
            value: seq.to_s
          },
          {
            type: 'input',
            input_type: 'text',
            name: "question[#{id}][id]",
            id: "question_#{id}",
            value: id.to_s
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
          { type: 'text', value: id.to_s },
          { type: 'text', value: '—' } # Placeholder for non-applicable fields
        ]
      }.to_json
    end
  
  
    # Implement this method for completing a question
    def complete(count, answer = nil)
      # Implement the logic for completing a question
    end
  
    # Implement this method for viewing a completed question by a student
    def view_completed_question(count, files)
      # Implement the logic for viewing a completed question by a student
    end
  end
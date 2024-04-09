# Inherits from Question to define specific behaviors for text response questions
class TextResponse < Question
  # Validates the presence of the size attribute
  validates :size, presence: true

  def edit(_count)
    {
      action: 'edit',  # Indicates the action type
      elements: [  # Array of elements comprising the edit form
        {
          type: 'link',  # Type of element (link)
          text: 'Remove',  # Text for the link
          href: "/questions/#{id}",  # URL for the link
          method: 'delete'  # HTTP method for the link
        },
        {
          type: 'input',  # Type of element (input)
          input_type: 'text',  # Type of input (text)
          size: 6,
          name: "question[#{id}][seq]",  # Name attribute for form submission
          id: "question_#{id}_seq",  # ID attribute for HTML element
          value: seq.to_s  # Value of the input field, converted to string
        },
        {
          type: 'textarea',  # Type of element (textarea)
          cols: 50,  # Number of columns for the textarea
          rows: 1,  # Number of rows for the textarea
          name: "question[#{id}][txt]",  # Name attribute for form submission
          id: "question_#{id}_txt",  # ID attribute for HTML element
          placeholder: 'Edit question content here',  # Placeholder text for the textarea
          value: txt  # Value of the textarea
        },
        {
          type: 'input',  # Type of element (input)
          input_type: 'text',  # Type of input (text)
          size: 10,
          name: "question[#{id}][question_type]",  # Name attribute for form submission
          id: "question_#{id}_question_type",  # ID attribute for HTML element
          value: question_type,  # Value of the input field
          disabled: true  # Indicates whether the input is disabled
        },
        {
          type: 'input',  # Type of element (input)
          input_type: 'text',  # Type of input (text)
          size: 6,
          name: "question[#{id}][size]",  # Name attribute for form submission
          id: "question_#{id}_size",  # ID attribute for HTML element
          value: size,  # Value of the input field
          label: 'Text area size'  # Label for the input field
        }
      ]
    }.to_json  # Converts the hash to JSON format
  end

  def view_question_text
    {
      action: 'view_question_text',  # Indicates the action type
      elements: [  # Array of elements comprising the question view
        { type: 'text', value: txt },  # Text element displaying the question text
        { type: 'text', value: question_type },  # Text element displaying the question type
        { type: 'text', value: weight.to_s },  # Text element displaying the question weight (converted to string)
        { type: 'text', value: '—' }  # Placeholder text element (not specified in the requirement)
      ]
    }.to_json  # Converts the hash to JSON format
  end
end
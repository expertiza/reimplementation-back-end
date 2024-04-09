# Inherits from UnscoredQuestion, defining behaviors specific to checkbox questions
class Checkbox < UnscoredQuestion

  # Builds the edit view structure for a checkbox question
  def edit(count)
    {
      remove_button: edit_remove_button(count),  # Structure for the remove button
      seq: edit_seq(count),  # Structure for question sequence input
      question: edit_question(count),  # Structure for editing the question content
      type: edit_type(count),  # Structure for displaying the question type
      weight: edit_weight(count)  # Structure for displaying the weight (not applicable for UnscoredQuestion)
    }
  end

  # Defines the remove button component in the edit view
  def edit_remove_button(count)
    {
      type: 'remove_button',  # Component type
      action: 'delete',  # Action associated with the button
      href: "/questions/#{id}",  # URL for the delete action
      text: 'Remove'  # Button text
    }
  end

  # Defines the sequence input component in the edit view
  def edit_seq(count)
    {
      type: 'seq',  # Component type
      input_size: 6,  # Size attribute of the input
      value: seq,  # Current sequence value
      name: "question[#{id}][seq]",  # Input name
      id: "question_#{id}_seq"  # Input id
    }
  end

  # Defines the question content editing component in the edit view
  def edit_question(count)
    {
      type: 'textarea',  # Component type
      cols: 50,  # Columns attribute of the textarea
      rows: 1,  # Rows attribute of the textarea
      name: "question[#{id}][txt]",  # Textarea name
      id: "question_#{id}_txt",  # Textarea id
      placeholder: 'Edit question content here',  # Placeholder text
      content: txt  # Current question content
    }
  end

  # Defines the question type display component in the edit view
  def edit_type(count)
    {
      type: 'text',  # Component type
      input_size: 10,  # Size attribute of the input
      disabled: true,  # Disabled attribute to make it read-only
      value: question_type,  # Current question type
      name: "question[#{id}][type]",  # Input name
      id: "question_#{id}_type"  # Input id
    }
  end

  # Defines the weight display component in the edit view (not applicable for UnscoredQuestion)
  def edit_weight(count)
    {
      type: 'weight',  # Component type
      placeholder: 'UnscoredQuestion does not need weight'  # Placeholder text indicating weight is not applicable
    }
  end

  # Builds the structure to view question text and related details
  def view_question_text
    {
      content: txt,  # Question content
      type: question_type,  # Question type
      weight: weight.to_s,  # Question weight as a string
      checked_state: 'Checked/Unchecked'  # Placeholder for checked state description
    }
  end

  # Constructs the completion structure for a checkbox question, including inputs and scripts
  def complete(count, answer = nil)
    {
      previous_question: check_previous_question,  # Checks and indicates if the previous question is a column header
      inputs: [  # Array of input structures for the question
        complete_first_second_input(count, answer),  # Hidden inputs for comments and score
        complete_third_input(count, answer)  # Checkbox input for the actual question response
      ],
      label: {  # Label structure for the checkbox
        for: "responses_#{count}",  # Associated input id
        text: txt  # Question text as the label
      },
      script: complete_script(count),  # Script to handle checkbox change events
      if_column_header: complete_if_column_header  # Indicates if the next question is a column header or other special type
    }
  end

  # Checks if the previous question is a column header and returns the appropriate structure
  def check_previous_question
    prev_question = Question.where('seq < ?', seq).order(:seq).last  # Finds the last question before this one by sequence
    {
      type: prev_question&.type == 'ColumnHeader' ? 'ColumnHeader' : 'other'  # Indicates if the previous question is a column header
    }
  end

  # Hidden inputs for comments and score, used in the complete structure
  def complete_first_second_input(count, answer = nil)
    [
      {
        id: "responses_#{count}_comments",  # Input id for comments
        name: "responses[#{count}][comment]",  # Input name for comments
        type: 'hidden',  # Input type hidden
        value: ''  # Default value
      },
      {
        id: "responses_#{count}_score",  # Input id for score
        name: "responses[#{count}][score]",  # Input name for score
        type: 'hidden',  # Input type hidden
        value: answer&.answer == 1 ? '1' : '0'  # Value based on answer
      }
    ]
  end

  # Checkbox input for the actual question response in the complete structure
  def complete_third_input(count, answer = nil)
    {
      id: "responses_#{count}_checkbox",  # Checkbox id
      type: 'checkbox',  # Input type checkbox
      onchange: "checkbox#{count}Changed()",  # Onchange script function
      checked: answer&.answer == 1  # Checked state based on answer
    }
  end

  # JavaScript function to update the hidden score input based on checkbox state
  def complete_script(count)
    "function checkbox#{count}Changed() { var checkbox = jQuery('#responses_#{count}_checkbox'); var response_score = jQuery('#responses_#{count}_score'); if (checkbox.is(':checked')) { response_score.val('1'); } else { response_score.val('0'); }}"
  end

  # Determines the flow after this question based on the type of the next question
  def complete_if_column_header
    next_question = Question.where('seq > ?', seq).order(:seq).first  # Finds the first question after this one by sequence
    if next_question
      case next_question.question_type
      when 'ColumnHeader'  # Next question is a column header
        'end_of_column_header'
      when 'SectionHeader', 'TableHeader'  # Next question is a section or table header
        'end_of_section_or_table'
      else  # Continues with more questions of standard types
        'continue'
      end
    else  # This is the last question
      'end'
    end
  end

  # Builds the structure for viewing a completed question, including previous question check and answer details
  def view_completed_question(count, answer)
    {
      previous_question: check_previous_question,  # Checks and indicates if the previous question is a column header
      answer: view_completed_question_answer(count, answer),  # Structure for displaying the given answer
      if_column_header: view_completed_question_if_column_header  # Indicates if the next question is a column header or other special type
    }
  end

  # Structure for displaying the given answer in the completed question view
  def view_completed_question_answer(count, answer)
    {
      number: count,  # Question number
      image: answer.answer == 1 ? 'Check-icon.png' : 'delete_icon.png',  # Icon based on answer
      content: txt,  # Question content
      bold: true  # Bold formatting for display
    }
  end

  # Determines the flow after this question in the completed question view based on the type of the next question
  def view_completed_question_if_column_header
    next_question = Question.where('seq > ?', seq).order(:seq).first  # Finds the first question after this one by sequence
    if next_question
      case next_question.question_type
      when 'ColumnHeader'  # Next question is a column header
        'end_of_column_header'
      when 'TableHeader'  # Next question is a table header
        'end_of_table_header'
      else  # Continues with more questions of standard types
        'continue'
      end
    else  # This is the last question
      'end'
    end
  end
end
module ResponseHelper

    #Combine functionality of set_content and assign_action_parameters
    def prepare_response_content(map, current_round, action_params = nil, new_response = false)
      # Set title and other initial content based on the map
      title = map.get_title
      survey_parent = nil
      assignment = nil
      participant = map.reviewer
      contributor = map.contributor

      if map.survey?
        survey_parent = map.survey_parent
      else
        assignment = map.assignment
      end

      # Initialize response if new_response is true
      response = nil
      if new_response
        response = Response.where(map_id: map.id, round: current_round.to_i).order(updated_at: :desc).first
        if response.nil?
          response = Response.create(map_id: map.id, additional_comment: '', round: current_round.to_i, is_submitted: 0)
        end
      end

      # Get the questionnaire and sort questions
      questionnaire = questionnaire_from_response_map(map)
      review_questions = sort_questions(questionnaire.questions)
      min = questionnaire.min_question_score
      max = questionnaire.max_question_score

      # Set up dropdowns or scales
      set_dropdown_or_scale

      # Process the action parameters if provided
      if action_params
        case action_params[:action]
        when 'edit'
          header = 'Edit'
          next_action = 'update'
          response = Response.find(action_params[:id])
          map = response.map
          contributor = map.contributor
        when 'new'
          header = 'New'
          next_action = 'create'
          feedback = action_params[:feedback]
          map = ResponseMap.find(action_params[:id])
          modified_object = map.id
        end
      end

      # Return the data as a hash
      {
        title: title,
        survey_parent: survey_parent,
        assignment: assignment,
        participant: participant,
        contributor: contributor,
        response: response,
        review_questions: review_questions,
        min: min,
        max: max,
        header: header || 'Default Header',
        next_action: next_action || 'create',
        feedback: feedback,
        map: map,
        modified_object: modified_object,
        return: action_params ? action_params[:return] : nil
      }
    end

    def set_dropdown_or_scale
        @dropdown_or_scale = if AssignmentQuestionnaire.exists?(assignment_id: @assignment&.id, 
                                                                 questionnaire_id: @questionnaire&.id, 
                                                                 dropdown: true)
                                'dropdown'
                            else
                                'scale'
                            end
      end

end
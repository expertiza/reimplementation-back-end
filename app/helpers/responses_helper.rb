module ResponsesHelper
    def questionnaire_from_response_map(map, contributor, assignment)
        if ['ReviewResponseMap', 'SelfReviewResponseMap'].include?(map.type)
            get_questionnaire_by_contributor(map, contributor, assignment)
        else
            get_questionnaire_by_duty(map, assignment)
        end
    end
    def get_questionnaire_by_contributor(map, contributor, assignment)
        
        reviewees_topic = SignedUpTeam.find_by(team_id: contributor.id)&.sign_up_topic_id
        current_round = DueDate.next_due_date(reviewees_topic).round
        map.questionnaire(current_round, reviewees_topic)
    end
    def get_questionnaire_by_duty(map, assignment)
        if assignment.duty_based_assignment?
            # E2147 : gets questionnaire of a particular duty in that assignment rather than generic questionnaire
            map.questionnaire_by_duty(map.reviewee.duty_id)
        else
            map.questionnaire
        end
    end

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
        questionnaire = questionnaire_from_response_map(map, contributor, assignment)
        review_questions = Response.sort_by_version(questionnaire.questions)
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

    def action_allowed

    end

    #Renamed to sort_items from sort_questions
    def sort_items(questions)
      questions.sort_by(&:seq)
    end
end
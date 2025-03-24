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
    def prepare_response_content(map, action_params = nil, new_response = false)
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
  
        # Get the questionnaire and sort questions
        questionnaire = questionnaire_from_response_map(map, contributor, assignment)
        review_questions = Response.sort_by_version(questionnaire.questions)
        min = questionnaire.min_question_score
        max = questionnaire.max_question_score

        # Initialize response if new_response is true
        response = nil
        if new_response
          response = Response.where(map_id: map.id).order(updated_at: :desc).first
          if response.nil?
            response = Response.create(map_id: map.id, additional_comment: '', is_submitted: 0)
          end
        end
  

  
        # Set up dropdowns or scales
        set_dropdown_or_scale
  
        
        # Process the action parameters if provided
        if action_params
          case action_params[:action]
          when 'edit'
            header = 'Edit'
            next_action = 'update'
            response = Response.find(action_params[:id])
            contributor = map.contributor
          when 'new'
            header = 'New'
            next_action = 'create'
            feedback = action_params[:feedback]
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

    def init_answers(response, questions)
      questions.each do |q|
        # it's unlikely that these answers exist, but in case the user refresh the browser some might have been inserted.
        answer = Answer.where(response_id: response.id, question_id: q.id).first
        if answer.nil?
          Answer.create(response_id: response.id, question_id: q.id, answer: nil, comments: '')
        end
      end
    end
  
  # Assigns total contribution for cake question across all reviewers to a hash map
  # Key : question_id, Value : total score for cake question
  def total_cake_score
    reviewee = ResponseMap.select(:reviewee_id, :type).where(id: @response.map_id.to_s).first
    return Cake.get_total_score_for_questions(reviewee.type,
                                                      @review_questions,
                                                      @participant.id,
                                                      @assignment.id,
                                                      reviewee.reviewee_id)
  end

  def find_or_create_feedback
    map = FeedbackResponseMap.where(reviewed_object_id: @review.id, reviewer_id: @reviewer.id).first
    if map.nil?
      map = FeedbackresponseMap.create(reviewed_object_id: @review.id, reviewer_id: @reviewer.id, reviewee_id: @review.map.reviewer.id)
    end
    return map
  end
end
require 'response_helper'
class ResponseDtoHandler
  attr_reader :response, :res_helper
  include 'enum_response_map'
  def initialize(response)
    @res_helper = ResponseHelper.new
    @response = response
  end
  
  def accept_content(params, action)
    map_id = params[:id]
    unless params[:map_id].nil?
      map_id = params[:map_id]
    end # pass map_id as a hidden field in the review form
    
    map = ResponseMap.find(map_id)
    round = nil
    if params[:review][:questionnaire_id]
      questionnaire = Questionnaire.find(params[:review][:questionnaire_id])
      round = params[:review][:round]
    else
      round = nil
    end
    is_submitted = (params[:isSubmit] == 'Yes')
    # There could be multiple responses per round, when re-submission is enabled for that round.
    # Hence we need to pick the latest response.
    @response = Response.where(map_id: map.id, round: round.to_i).order(created_at: :desc).first
    if @response.nil?
      @response = Response.create(map_id: map.id, additional_comment: params[:review][:comments],
                                  round: round.to_i, is_submitted: is_submitted)
    end
    was_submitted = response.is_submitted
    # ignore if autoupdate try to save when the response object is not yet created.s
    @response.update(additional_comment: params[:review][:comments], is_submitted: is_submitted)
    @response.response_map = map
    # :version_num=>@version)
    # Change the order for displaying questions for editing response views.
    questions = @res_helper.sort_questions(questionnaire.questions)
    @res_helper.create_answers(response, params, questions) if params[:responses]
    return {
      response => @response,
      questionnaire => questionnaire,
      was_submitted => was_submitted
      }
    
  end

  # new_response if a flag parameter indicating that if user is requesting a new rubric to fill
  # if true: we figure out which questionnaire to use based on current time and records in assignment_questionnaires table
  # e.g. student click "Begin" or "Update" to start filling out a rubric for others' work
  # if false: we figure out which questionnaire to display base on response_dto.response object
  # e.g. student click "Edit" or "View"
  def set_content(new_response = false, action, params, errors)
    response_dto = ResponseDto.new
    assign_action_parameters(action, response_dto, params, errors)
    response_dto.title = response_dto.response.response_map.get_title
    if response_dto.response.response_map.type == EnumResponseMap::SURVEY_RESPONSE_MAP
      response_dto.survey_parent = response_dto.response.response_map.survey_parent
    else
      response_dto.assignment = response_dto.response_map.assignment
    end
    response_dto.assignment = response_dto.response_map.assignment
    response_dto.participant = response_dto.response_map.reviewer
    if response_dto.response.response_map.contributor.present?
    response_dto.contributor = response_dto.map.contributor
    end
    # Todo : skipped, done
    # new_response ? @res_helper.questionnaire_from_response_map(response_dto) : @res_helper.questionnaire_from_response(response_dto)

    response_dto.questionnaire = response_dto.response.response_map.get_questionnaire
    response_dto.dropdown_or_scale = @res_helper.set_dropdown_or_scale(response_dto)
    # Todo: created new methods for @res_helper.questionnaire_from_response_map
    # Onlu the ReviewResponseMap class will be used for testing.
    # response_dto.questionnaire = Questionnaire.find(1)
    # response_dto.review_questions = @res_helper.get_all_questions_by_questionnaire_id(response_dto.questionnaire.id)
    response_dto.questionnaire = Questionnaire.find(1)
    response_dto.review_questions = Question.where("questionnaire_id = ?", response_dto.questionnaire.id).order('seq')
    # response_dto.review_questions = @res_helper.sort_questions([response_dto.review_questions])
    response_dto.min = response_dto.questionnaire.min_question_score
    response_dto.max = response_dto.questionnaire.max_question_score
    response_dto.current_round = 1
    # The new response is created here so that the controller has access to it in the new method
    # This response object is populated later in the new method
    if new_response
      #Sometimes the response is already created and the new controller is called again (page refresh)
      response_dto.response = Response.where(map_id: response_dto.response_map.id, round: response_dto.current_round.to_i).order(updated_at: :desc).first
      if response_dto.response.nil?
        response_dto.response = Response.create(map_id: response_dto.response_map.id, additional_comment: '', round: response_dto.current_round.to_i, is_submitted: 0)
      end
    end
    return response_dto
  end
  # This method is called within the Edit or New actions
  # It will create references to the objects that the controller will need when a user creates a new response or edits an existing one.
  def assign_action_parameters(action, response_dto, params, errors)
    case action
    when 'edit'
      response_dto.header = 'Edit'
      response_dto.next_action = 'update'
      response_dto.response = @response
      if response_dto.response.nil?
        return errors.push(' Not found response')
      end
      response_dto.response.response_map = response_dto.response.get_response_map_by_type(response_dto.response.id)
      response_dto.map = response_dto.response.response_map
      response_dto.contributor = response_dto.map.contributor
    when 'new'
      response_dto.header = 'New'
      response_dto.next_action = 'create'
      response_dto.response = @response
      response_dto.map = ResponseMap.find(params[:map_id])
      if response_dto.map.nil?
        return errors.push(' Not found response map')
      end
      response_dto.response.response_map = response_dto.response.get_response_map_by_type(params[:map_id])
      response_dto.modified_object = response_dto.map.id
    end
    if params[:return].present?
    response_dto.return = params[:return]
    end
  end
end
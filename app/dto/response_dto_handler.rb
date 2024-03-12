require 'response_helper'

class ResponseDtoHandler
  attr_reader :response, :res_helper
  def initialize(response)
    @res_helper = ResponseHelper.new
    @response = response
  end
  
  def accept_content(params, action)
    if @response.response_map.id.present?
      map_id = @response.response_map.id
    else
      map_id = params[:map_id]
    end
    @response.response_map = ResponseMap.find(map_id)
    if @response.response_map.nil
      errors.push("Not found response map")
    else
      @response.round = params[:response][:round]
      @response.comments = params[:response][:comments]
      @response.isSubmit = params[:response][:is_Submit]
      @response.version_num = params[:response][:version_num]
      @res_helper.create_answers(@response.id, params[:answers]) if params[:answers]
    end
  end

  def set_content(params, action)
    @response.response_map = ResponseMap.find(@response.map_id)
    if @response.response_map.nil?
      @errors.push(' Not found response map')
    else
      @response
    end
  end

end
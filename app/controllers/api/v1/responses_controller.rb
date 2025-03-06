class ResponseController < ApplicationController
    include ResponseHelper
    
    def json   # GET /response/json?response_id=xx
        response_id = params[:response_id] if params.key?(:response_id)
        response = Response.find(response_id)
        render json: response
    end

    def new 
        action_params = params.slice(:action, :id, :feedback, :return)
        response_data = ResponseService.prepare_response_data(@map, @current_round, action_params, true)
    end

    def edit
        action_params = params.slice(:action, :id, :feedback, :return)
        response_data = ResponseService.prepare_response_data(@map, @current_round, action_params)
    end

    def view
        action_params = params.slice(:action, :id, :feedback, :return)
        response_data = ResponseService.prepare_response_data(@map, @current_round, action_params)
    end

end
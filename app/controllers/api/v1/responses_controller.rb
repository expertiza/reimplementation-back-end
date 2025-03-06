class ResponseController < ApplicationController
    include ResponseHelper
    
    def json   # GET /response/json?response_id=xx
        response_id = params[:response_id] if params.key?(:response_id)
        response = Response.find(response_id)
        render json: response
    end

end
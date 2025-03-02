class ResponseController < ApplicationController

    
    def json   # GET /response/json?response_id=xx
        response_id = params[:response_id] if params.key?(:response_id)
        response = Response.find(response_id)
        render json: response
    end

    def create

    end

    def new

    end

    def save

    end

    def index

    end

    def show
        
    end

    def update

    end

    def edit

    end




end
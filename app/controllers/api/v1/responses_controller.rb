require 'responses_helper'
class Api::V1::ResponsesController < ApplicationController
  
  
  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    response = set_content(Action.SHOW, params)
    
    render json: response
  end


  private
  # E2218: Method to initialize response and response map for update, delete and view methods
  def set_response
    @response = Response.find(params[:id])
    @map = @response.map
  end
end
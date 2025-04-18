# app/controllers/api/v1/response_maps_controller.rb
class Api::V1::ResponseMapsController < ApplicationController
    before_action :set_response_map, only: [:show, :update, :destroy]
  
    # GET    /api/v1/response_maps
    def index
      render json: ResponseMap.all
    end
  
    # GET    /api/v1/response_maps/:id
    def show
      render json: @response_map
    end
  
    # POST   /api/v1/response_maps
    def create
      @response_map = ResponseMap.new(response_map_params)
      persist_and_respond(@response_map, :created)
    end
  
    # PATCH  /api/v1/response_maps/:id
    def update
      @response_map.assign_attributes(response_map_params)
      persist_and_respond(@response_map, :ok)
    end
  
    # DELETE /api/v1/response_maps/:id
    def destroy
      @response_map.destroy
      head :no_content
    end
  
    private
  
    def persist_and_respond(record, success_status)
      if record.save
        send_feedback_email_if_submitted(record)
        render json: record, status: success_status
      else
        render json: record.errors, status: :unprocessable_entity
      end
    end
  
    def send_feedback_email_if_submitted(response_map)
      return unless ActiveModel::Type::Boolean.new.cast(params[:submitted])
  
      # Use your FeedbackEmailService to build & deliver the mail
      FeedbackEmailService.new(response_map, response_map.assignment).call
    rescue StandardError => e
      Rails.logger.error "FeedbackEmailService failed: #{e.message}"
    end
  
    def set_response_map
      @response_map = ResponseMap.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Response map not found' }, status: :not_found
    end
  
    def response_map_params
      params.require(:response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
    end
  end
  
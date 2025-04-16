# app/controllers/api/v1/review_mappings_controller.rb

module Api
    module V1
      class ReviewMappingsController < ApplicationController
        before_action :set_review_mapping, only: [:show, :update, :destroy]
  
        # GET /api/v1/review_mappings
        def index
          @review_mappings = ReviewMapping.all
          render json: @review_mappings
        end
  
        # GET /api/v1/review_mappings/:id
        def show
          render json: @review_mapping
        end
  
        # POST /api/v1/review_mappings
        def create
          @review_mapping = ReviewMapping.new(review_mapping_params)
  
          if @review_mapping.save
            render json: @review_mapping, status: :created
          else
            render json: @review_mapping.errors, status: :unprocessable_entity
          end
        end
  
        # PATCH/PUT /api/v1/review_mappings/:id
        def update
          if @review_mapping.update(review_mapping_params)
            render json: @review_mapping
          else
            render json: @review_mapping.errors, status: :unprocessable_entity
          end
        end
  
        # DELETE /api/v1/review_mappings/:id
        def destroy
          @review_mapping.destroy
          head :no_content
        end
  
        # POST /api/v1/review_mappings/add_calibration
        def add_calibration
          result = ReviewMapping.create_calibration_review(
            assignment_id: calibration_params[:assignment_id],
            team_id: calibration_params[:team_id],
            user_id: current_user.id
          )
  
          if result.success?
            render json: {
              message: 'Calibration review mapping created successfully',
              review_mapping: result.review_mapping,
              response_url: new_api_v1_response_path(
                review_mapping_id: result.review_mapping.id,
                assignment_id: calibration_params[:assignment_id]
              )
            }, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        private
  
        def set_review_mapping
          @review_mapping = ReviewMapping.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "ReviewMapping not found" }, status: :not_found
        end
  
        def review_mapping_params
          params.require(:review_mapping).permit(:reviewer_id, :reviewee_id, :review_type)
        end
  
        def calibration_params
          params.require(:calibration).permit(:assignment_id, :team_id)
        end
      end
    end
  end
  
# app/controllers/api/v1/review_mappings_controller.rb

module Api
  module V1
    class ReviewMappingsController < ApplicationController
      include ReviewMappingsHelper

      before_action :authorize_request
      before_action :set_review_mapping, only: [:show, :update, :destroy]

      # GET /api/v1/review_mappings
      def index
        render json: { message: "Use /assignments/:assignment_id/review_mappings to list mappings." }, status: :ok
      end

      # GET /api/v1/assignments/:assignment_id/review_mappings
      # This action fetches all review mappings associated with a specific assignment.
      # Optional query parameters (reviewer_id, reviewee_id, type) can be used to filter the results.
      def list_mappings
        # Whitelist and extract the relevant query parameters
        params.permit(:assignment_id, :reviewer_id, :reviewee_id, :type)

        # Find the assignment by the provided assignment_id
        assignment = Assignment.find_by(id: params[:assignment_id])

        # Return 404 Not Found if the assignment doesn't exist
        if assignment.nil?
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Extract optional filtering parameters
        filters = params.slice(:reviewer_id, :reviewee_id, :type)

        # Fetch the review mappings using the helper method with the given filters
        mappings_data = fetch_review_mappings(assignment, filters)

        # Respond with the filtered review mappings in JSON format
        render json: mappings_data, status: :ok
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

      private

      def set_review_mapping
        @review_mapping = ReviewMapping.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "ReviewMapping not found" }, status: :not_found
      end

      def review_mapping_params
        params.require(:review_mapping).permit(:reviewer_id, :reviewee_id, :review_type)
      end
    end
  end
end

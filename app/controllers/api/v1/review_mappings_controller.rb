# app/controllers/api/v1/review_mappings_controller.rb

module Api
    module V1
      class ReviewMappingsController < ApplicationController
        # Set up before actions for common operations
        before_action :set_review_mapping, only: [:show, :update, :destroy]
        before_action :validate_contributor_id, only: [:select_reviewer]
  
        # GET /api/v1/review_mappings
        # Returns a list of all review mappings
        def index
          @review_mappings = ReviewMapping.all
          render json: @review_mappings
        end
  
        # GET /api/v1/review_mappings/:id
        # Returns a specific review mapping by ID
        def show
          render json: @review_mapping
        end
  
        # POST /api/v1/review_mappings
        # Creates a new review mapping
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
        # Creates a calibration review mapping between a team and an assignment
        # This is used for calibration reviews where instructors review team submissions
        # to establish grading standards
        def add_calibration
          result = ReviewMapping.create_calibration_review(
            assignment_id: params.dig(:calibration, :assignment_id),
            team_id: params.dig(:calibration, :team_id),
            user_id: current_user.id
          )
  
          if result.success?
            render json: result.review_mapping, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        # GET /api/v1/review_mappings/select_reviewer
        # Selects a contributor for review mapping and stores it in the session
        # This is used in the review assignment process to track the selected contributor
        def select_reviewer
          @contributor = AssignmentTeam.find(params[:contributor_id])
          session[:contributor] = @contributor
        end
  
        # POST /api/v1/review_mappings/add_reviewer
        # Adds a reviewer to a review mapping
        # This endpoint handles the assignment of reviewers to teams for review purposes
        def add_reviewer
          result = ReviewMapping.add_reviewer(
            assignment_id: params[:id],
            team_id: params[:contributor_id],
            user_name: params.dig(:user, :name),
            topic_id: params[:topic_id]
          )
  
          if result.success?
            render json: result.review_mapping, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        # POST /api/v1/review_mappings/assign_reviewer_dynamically
        # Assigns a reviewer dynamically to a team or topic
        def assign_reviewer_dynamically
          result = ReviewMapping.assign_reviewer_dynamically(
            assignment_id: params[:assignment_id],
            reviewer_id: params[:reviewer_id],
            topic_id: params[:topic_id],
            i_dont_care: params[:i_dont_care].present?
          )
  
          if result.success?
            render json: result.review_mapping, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        private
  
        # Sets the review mapping instance variable based on the ID parameter
        # Used by show, update, and destroy actions
        def set_review_mapping
          @review_mapping = ReviewMapping.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "ReviewMapping not found" }, status: :not_found
        end
  
        # Validates that a contributor_id parameter is present in the request
        # Used by the select_reviewer action
        def validate_contributor_id
          unless params[:contributor_id].present?
            render json: { error: 'Contributor ID is required' }, status: :bad_request
          end
        end
  
        # Strong parameters for review mapping creation and updates
        # Ensures only permitted attributes can be mass-assigned
        def review_mapping_params
          params.require(:review_mapping).permit(:reviewer_id, :reviewee_id, :review_type)
        end
      end
    end
  end
  
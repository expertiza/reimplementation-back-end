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
  
          if result.success
            render json: result.review_mapping, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        # GET /api/v1/review_mappings/select_reviewer
        # Selects a contributor for review mapping and stores it in the session
        # This is used in the review assignment process to track the selected contributor
        def select_reviewer
          @contributor = Team.find(params[:contributor_id])
          session[:contributor] = @contributor
          render json: @contributor, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Contributor not found" }, status: :not_found
        end
  
        # POST /api/v1/review_mappings/add_reviewer
        # Adds a reviewer to a review mapping
        # This endpoint handles the assignment of reviewers to teams for review purposes
        def add_reviewer
          Rails.logger.debug "Raw params: #{params.inspect}"
          Rails.logger.debug "Request content type: #{request.content_type}"
          Rails.logger.debug "Request body: #{request.body.read}"
          
          begin
            result = ReviewMapping.add_reviewer(
              assignment_id: params[:id],
              team_id: params[:contributor_id],
              user_name: params.dig(:user, :name)
            )
  
            if result.success?
              render json: result.review_mapping, status: :created
            else
              render json: { error: result.error }, status: :unprocessable_entity
            end
          rescue => e
            Rails.logger.error "Error in add_reviewer: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            render json: { error: e.message }, status: :bad_request
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
          
        # GET /api/v1/review_mappings/review_allowed
        # Checks if a reviewer can perform more reviews for an assignment
        def review_allowed
          result = ReviewResponseMap.review_allowed?(params[:assignment_id], params[:reviewer_id])

          if result.success
            render plain: result.allowed.to_s
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        # GET /api/v1/review_mappings/check_outstanding_reviews
        # Checks if a reviewer has exceeded the maximum number of outstanding reviews
        def check_outstanding_reviews
          result = ReviewMapping.check_outstanding_reviews?(
            Assignment.find(params[:assignment_id]),
            User.find(params[:reviewer_id])
          )

          if result.success
            render plain: result.allowed.to_s
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Assignment or Reviewer not found" }, status: :unprocessable_entity
        end
  
        # POST /api/v1/review_mappings/assign_quiz_dynamically
        # Assigns a quiz to a participant for a specific assignment
        def assign_quiz_dynamically
          result = QuizResponseMap.assign_quiz(
            assignment_id: params[:assignment_id],
            reviewer_id: params[:reviewer_id],
            questionnaire_id: params[:questionnaire_id]
          )

          if result.success
            render json: result.quiz_response_map, status: :created
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
  
        # POST /api/v1/review_mappings/start_self_review
        # Initiates a self-review process for a participant
        def start_self_review
          Rails.logger.debug "Starting self-review with params: #{params.inspect}"
          
          result = SelfReviewResponseMap.create_self_review(
            assignment_id: params[:assignment_id],
            reviewer_id: params[:reviewer_id],
            reviewer_userid: params[:reviewer_userid]
          )

          Rails.logger.debug "Self-review result: #{result.inspect}"
          
          if result.success
            render json: result.self_review_map, status: :created
          else
            error_message = result.error || "Unknown error occurred during self-review creation"
            Rails.logger.error "Self-review error: #{error_message}"
            render json: { error: error_message }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Exception in start_self_review: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: e.message }, status: :unprocessable_entity
        end
  
        # GET /api/v1/review_mappings/get_questionnaire_id
        # Returns the questionnaire ID for a given assignment and reviewer
        def get_questionnaire_id
          assignment = Assignment.find(params[:assignment_id])
          reviewer = User.find(params[:reviewer_id])

          # Get the review questionnaire for the assignment
          questionnaire = assignment.review_questionnaire_id

          if questionnaire
            render json: { questionnaire_id: questionnaire.id }, status: :ok
          else
            render json: { error: "No questionnaire found for this assignment" }, status: :not_found
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Assignment or Reviewer not found" }, status: :not_found
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
  
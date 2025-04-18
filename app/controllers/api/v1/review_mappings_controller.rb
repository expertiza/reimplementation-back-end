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

      # POST /api/v1/assignments/:assignment_id/automatic_review_mapping
      # Automatically generates reviewer-reviewee mappings for a given assignment.
      def automatic_review_mapping
        # Permit only the expected parameters from the request
        params.permit(:assignment_id, :num_reviews_per_student, :num_of_reviewers, :strategy)

        # Find the assignment using the provided assignment_id
        assignment = Assignment.find_by(id: params[:assignment_id])

        # Return a 404 error if the assignment does not exist
        if assignment.nil?
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Delegate the mapping generation logic to the helper function
        result = generate_automatic_review_mappings(assignment, params)

        # If successful, return a success message with status 200
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          # If mapping fails, return an error message with status 422
          render json: { error: result[:message] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/assignments/:assignment_id/automatic_review_mapping_strategy
      def automatic_review_mapping_strategy
        # Allow only the permitted parameters from the incoming request.
        # These include the assignment ID (from the URL), number of reviews per student, and the desired strategy.
        params.permit(:assignment_id, :num_reviews_per_student, :strategy)

        # Attempt to find the Assignment record based on the provided assignment_id.
        # If no such assignment exists, respond with a 404 Not Found error.
        assignment = Assignment.find_by(id: params[:assignment_id])
        if assignment.nil?
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Pass control to the helper method responsible for generating review mappings
        # using the specified strategy. The helper handles logic variations based on the strategy value.
        result = generate_review_mappings_with_strategy(assignment, params)

        # Check the result returned by the helper method.
        # If successful, return a success message with HTTP 200 OK.
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { error: result[:message] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/assignments/:assignment_id/automatic_review_mapping_staggered
      def automatic_review_mapping_staggered
        # Permit only the required params for safety
        params.permit(:assignment_id, :num_reviews_per_student, :strategy)

        # Find the assignment by ID
        assignment = Assignment.find_by(id: params[:assignment_id])
        if assignment.nil?
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Delegate to helper that supports both individual and team-based strategies
        result = generate_staggered_review_mappings(assignment, params)

        # Render based on success/failure
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { error: result[:message] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/assignments/:assignment_id/assign_reviewers_for_team
      # This endpoint assigns a fixed number of reviewers to a specific team within an assignment.
      # It supports both team-based and individual assignments.
      def assign_reviewers_for_team
        # Allow only permitted parameters from the request
        params.permit(:assignment_id, :team_id, :num_reviewers)

        # Locate the assignment using the provided ID
        assignment = Assignment.find_by(id: params[:assignment_id])
        if assignment.nil?
          # Return 404 if the assignment does not exist
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Locate the target team using the provided ID
        team = Team.find_by(id: params[:team_id])
        if team.nil?
          # Return 404 if the team is not found
          render json: { error: 'Team not found' }, status: :not_found
          return
        end

        # Set the number of reviewers, defaulting to 3 if not specified
        num_reviewers = params[:num_reviewers]&.to_i || 3

        # Delegate logic to helper method to perform the assignment
        result = assign_reviewers_for_team_logic(assignment, team, num_reviewers)

        # Return the outcome based on the helper result
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { error: result[:message] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/assignments/:assignment_id/peer_review_strategy
      def peer_review_strategy
        # Permit and extract required parameters
        params.permit(:assignment_id, :num_reviews_per_student, :strategy)

        # Find the assignment by ID
        assignment = Assignment.find_by(id: params[:assignment_id])
        if assignment.nil?
          render json: { error: 'Assignment not found' }, status: :not_found
          return
        end

        # Delegate core peer review logic to helper
        result = generate_peer_review_strategy(assignment, params)

        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { error: result[:message] }, status: :unprocessable_entity
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
    end
  end
end

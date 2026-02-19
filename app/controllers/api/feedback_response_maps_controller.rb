module Api
  
    # Handles operations specific to feedback response maps
    # Inherits from ResponseMapsController to leverage common functionality
    # while providing specialized behavior for feedback
    class FeedbackResponseMapsController < ResponseMapsController
      # Overrides the base controller's set_response_map method
      # to specifically look for FeedbackResponseMap instances
      # @raise [ActiveRecord::RecordNotFound] if the feedback response map isn't found
      def set_response_map
        @response_map = FeedbackResponseMap.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Feedback response map not found' }, status: :not_found
      end

      # Retrieves all feedback response maps for a specific assignment
      # Useful for instructors to monitor feedback activity
      # GET /api/feedback_response_maps/assignment/:assignment_id
      def assignment_feedback
        @feedback_maps = FeedbackResponseMap
          .joins(:assignment)
          .where(assignments: { id: params[:assignment_id] })
        render json: @feedback_maps
      end

      # Gets all feedback maps for a specific reviewer
      # Includes the associated responses for comprehensive feedback history
      # GET /api/feedback_response_maps/reviewer/:reviewer_id
      def reviewer_feedback
        @feedback_maps = FeedbackResponseMap
          .where(reviewer_id: params[:reviewer_id])
          .includes(:responses)
        render json: @feedback_maps, include: :responses
      end

      # Calculates and returns feedback response statistics for an assignment
      # Includes total maps, completed maps, and response rate percentage
      # GET /api/feedback_response_maps/response_rate/:assignment_id
      def feedback_response_rate
        assignment_id = params[:assignment_id]
        total_maps = FeedbackResponseMap
          .joins(:assignment)
          .where(assignments: { id: assignment_id })
          .count
        
        completed_maps = FeedbackResponseMap
          .joins(:assignment)
          .where(assignments: { id: assignment_id })
          .joins(:responses)
          .where(responses: { is_submitted: true })
          .distinct
          .count

        render json: {
          total_feedback_maps: total_maps,
          completed_feedback_maps: completed_maps,
          response_rate: total_maps > 0 ? (completed_maps.to_f / total_maps * 100).round(2) : 0
        }
      end

      private

      # Defines permitted parameters specific to feedback response maps
      # @return [ActionController::Parameters] Whitelisted parameters
      def response_map_params
        params.require(:feedback_response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
      end

      # Ensures that we create a FeedbackResponseMap instance
      # instead of a base ResponseMap
      # POST /api/feedback_response_maps
      def create
        @response_map = FeedbackResponseMap.new(response_map_params)
        persist_and_respond(@response_map, :created)
      end
    end
  end
end
module Api
  module V1
    class FeedbackResponseMapsController < ResponseMapsController
      # Override to use FeedbackResponseMap model instead of base ResponseMap
      def set_response_map
        @response_map = FeedbackResponseMap.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Feedback response map not found' }, status: :not_found
      end

      # GET /api/v1/feedback_response_maps/assignment/:assignment_id
      def assignment_feedback
        @feedback_maps = FeedbackResponseMap
          .joins(:assignment)
          .where(assignments: { id: params[:assignment_id] })
        render json: @feedback_maps
      end

      # GET /api/v1/feedback_response_maps/reviewer/:reviewer_id
      def reviewer_feedback
        @feedback_maps = FeedbackResponseMap
          .where(reviewer_id: params[:reviewer_id])
          .includes(:responses)
        render json: @feedback_maps, include: :responses
      end

      # GET /api/v1/feedback_response_maps/response_rate/:assignment_id
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

      def response_map_params
        params.require(:feedback_response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
      end

      # Override create to ensure we're creating a FeedbackResponseMap
      def create
        @response_map = FeedbackResponseMap.new(response_map_params)
        persist_and_respond(@response_map, :created)
      end
    end
  end
end
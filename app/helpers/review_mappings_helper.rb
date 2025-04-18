# app/helpers/review_mappings_helper.rb
module ReviewMappingsHelper
    # Fetches review mappings for a given assignment with optional filtering by reviewer_id, reviewee_id, and type.
    #
    # @param assignment [Assignment] the assignment for which review mappings are requested
    # @param filters [Hash] optional filters for reviewer_id, reviewee_id, and type
    # @return [Array<Hash>] array of formatted review mapping hashes
    def fetch_review_mappings(assignment, filters = {})
      # Start by fetching all response maps for the given assignment
      mappings = ResponseMap.where(reviewed_object_id: assignment.id)
  
      # Apply optional filters if provided
      mappings = mappings.where(reviewer_id: filters[:reviewer_id]) if filters[:reviewer_id].present?
      mappings = mappings.where(reviewee_id: filters[:reviewee_id]) if filters[:reviewee_id].present?
  
      # Filter by STI 'type' column only if the 'type' column exists in the table
      mappings = mappings.where(type: filters[:type]) if filters[:type].present? && ResponseMap.column_names.include?('type')
  
      # Eager load associated reviewer and reviewee user records to avoid N+1 query problems
      mappings = mappings.includes(:reviewer, :reviewee) unless mappings.blank?
  
      # Format each mapping into a JSON-compatible hash
      mappings.map do |mapping|
        {
          id: mapping.id,
          assignment_id: mapping.reviewed_object_id,
          reviewer_id: mapping.reviewer_id,
          reviewer_name: mapping.reviewer.try(:name),
          reviewee_id: mapping.reviewee_id,
          reviewee_name: mapping.reviewee.try(:name),
          type: mapping.try(:type) || mapping.class.name # fallback to class name if type is nil
        }
      end
    end
  end
  
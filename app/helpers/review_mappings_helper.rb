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

    def generate_automatic_review_mappings(assignment, options = {})
        # Extract the number of reviews each student should perform. Default is 3 if not provided.
        num_reviews_per_student = options[:num_reviews_per_student]&.to_i || 3
    
        # Optional parameter: number of reviewers to consider — currently not used in the logic.
        num_of_reviewers = options[:num_of_reviewers]&.to_i
    
        # Strategy for assignment (e.g., 'default', 'topic-based', etc.). Currently only 'default' is implemented.
        strategy = options[:strategy] || "default"
    
        # Get all participants in the assignment and shuffle them to ensure random reviewer-reviewee combinations.
        participants = assignment.participants.to_a.shuffle
    
        # Check if there are at least 2 participants. Otherwise, review mappings cannot be generated.
        if participants.size < 2
        return { success: false, message: "Not enough participants to assign reviews." }
        end
    
        # Counter to keep track of how many new mappings are created
        created_count = 0
    
        # Loop through each participant to assign them as a reviewer
        participants.each do |reviewer|
        # Exclude the reviewer from the list of potential reviewees to avoid self-review
        potential_reviewees = participants.reject { |p| p.id == reviewer.id }
    
        # Randomly select N reviewees (as per num_reviews_per_student) from the list of potential reviewees
        reviewees_to_assign = potential_reviewees.sample(num_reviews_per_student)
    
        # For each selected reviewee, attempt to create a review mapping
        reviewees_to_assign.each do |reviewee|
            # Skip creation if this reviewer-reviewee mapping already exists to avoid duplicates
            next if ResponseMap.exists?(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: reviewee.id
            )
    
            # Create a new review mapping. Here, the 'type' is explicitly specified for STI compatibility.
            # In future, this could be changed to something like 'TeamReviewResponseMap' if needed.
            ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: reviewee.id,
            type: "ResponseMap"
            )
    
            # Increment the number of mappings created
            created_count += 1
        end
        end
    
        # Return success along with a message indicating how many mappings were created and which strategy was used
        {
        success: true,
        message: "Successfully created #{created_count} review mappings using strategy '#{strategy}'."
        }
    end

    # Generates automatic review mappings for a given assignment based on the selected strategy.
    # Supports multiple strategies like "default", "round_robin", etc.
    def generate_review_mappings_with_strategy(assignment, options = {})
    # Extract the number of reviews per student from options, defaulting to 3 if not provided
    num_reviews = options[:num_reviews_per_student]&.to_i || 3

    # Extract the chosen strategy, defaulting to "default"
    strategy = options[:strategy] || "default"

    # Retrieve and shuffle all participants to randomize assignment
    participants = assignment.participants.to_a.shuffle

    # Ensure there are at least two participants for mapping
    return { success: false, message: "Not enough participants." } if participants.size < 2

    created_count = 0

    case strategy
    when "default"
    # Default strategy: randomly assign `num_reviews` reviewees to each reviewer,
    # ensuring no self-review and avoiding duplicate mappings
    participants.each do |reviewer|
        potential_reviewees = participants.reject { |p| p.id == reviewer.id }
        reviewees = potential_reviewees.sample(num_reviews)

        reviewees.each do |reviewee|
        # Create a review mapping only if one doesn't already exist
        unless ResponseMap.exists?(reviewed_object_id: assignment.id, reviewer_id: reviewer.id, reviewee_id: reviewee.id)
            ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: reviewee.id,
            type: "ResponseMap"
            )
            created_count += 1
        end
        end
    end

    when "round_robin"
    # Round-robin strategy: Assigns reviewees in a circular fashion,
    # skipping self-reviews and wrapping around the list
    participants.each_with_index do |reviewer, i|
        reviewees = []
        offset = 1

        # Select the next `num_reviews` participants after the reviewer in circular order
        while reviewees.size < num_reviews
        reviewee = participants[(i + offset) % participants.size]
        reviewees << reviewee unless reviewee.id == reviewer.id
        offset += 1
        end

        reviewees.each do |reviewee|
        # Avoid creating duplicate mappings
        unless ResponseMap.exists?(reviewed_object_id: assignment.id, reviewer_id: reviewer.id, reviewee_id: reviewee.id)
            ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: reviewee.id,
            type: "ResponseMap"
            )
            created_count += 1
        end
        end
    end

    else
    # Return an error if the strategy is not recognized
    return { success: false, message: "Unsupported strategy: #{strategy}" }
    end

    # Return a success message with the number of mappings created
    {
    success: true,
    message: "Created #{created_count} review mappings using strategy '#{strategy}'."
    }
    end

  
  end
  
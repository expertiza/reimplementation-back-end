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

    # Generates staggered reviewer-reviewee mappings for an assignment.
    # Supports both team-based and individual participant assignments.
    # Returns a success message or an error if conditions aren't met.
    def generate_staggered_review_mappings(assignment, options = {})
    # Extract configuration options from input or assign defaults
    num_reviews = options[:num_reviews_per_student]&.to_i || 3
    strategy = options[:strategy] || "default"

    # Select reviewers based on assignment type (teams or individuals)
    if assignment.has_teams
    reviewers = assignment.teams.to_a.shuffle              # Randomize teams as reviewers
    mapping_type = "ResponseMap"                           # Type used in STI (can be customized)
    else
    reviewers = assignment.participants.to_a.shuffle       # Randomize individual participants
    mapping_type = "ResponseMap"
    end

    # Fail fast if there are not enough reviewers to proceed
    return { success: false, message: "Not enough reviewers to create mappings." } if reviewers.size < 2

    created_count = 0

    # Loop over each reviewer and assign them staggered reviewees
    reviewers.each_with_index do |reviewer, index|
    reviewees = []
    offset = 1

    # Select num_reviews unique reviewees in staggered (offset-based) order
    while reviewees.size < num_reviews
        reviewee = reviewers[(index + offset) % reviewers.size]
        offset += 1

        # Skip self-review and duplicates
        next if reviewer == reviewee || reviewees.include?(reviewee)

        # Prevent self-assignment based on team or individual context
        if assignment.has_teams
        next if reviewer.id == reviewee.id
        else
        next if reviewer.user_id == reviewee.user_id
        end

        reviewees << reviewee
    end

    # Create response mapping records if they don't already exist
    reviewees.each do |reviewee|
        exists = ResponseMap.exists?(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: reviewee.id,
        type: mapping_type
        )

        unless exists
        ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: reviewee.id,
            type: mapping_type
        )
        created_count += 1
        end
    end
    end

    # Return a success response with mapping count
    {
    success: true,
    message: "Successfully created #{created_count} staggered review mappings using strategy '#{strategy}'."
    }
    end


    # Helper method to assign reviewers to a given team for an assignment
    # Supports both team-based and individual assignments
    def assign_reviewers_for_team_logic(assignment, team, num_reviewers)
        # Fetch all participants in the assignment
        participants = assignment.participants.to_a
    
        # Determine the list of eligible reviewers based on whether the assignment has teams
        eligible_reviewers = if assignment.has_teams
        # Select teams excluding the current one, then collect their participants
        other_teams = assignment.teams.where.not(id: team.id)
        other_teams.flat_map(&:participants)
        else
        # For individual assignments, select participants not in the target team
        participants.reject { |p| p.team_id == team.id }
        end.shuffle
    
        # Return error if not enough reviewers
        if eligible_reviewers.size < num_reviewers
        return {
            success: false,
            message: "Not enough eligible reviewers (found #{eligible_reviewers.size}, need #{num_reviewers})."
        }
        end
    
        # Randomly select reviewers
        selected_reviewers = eligible_reviewers.first(num_reviewers)
    
        # Determine mapping type (STI)
        mapping_type = "ResponseMap" # This can be extended to TeamReviewResponseMap later if needed
    
        # Track number of mappings created
        created_count = 0
    
        # Assign selected reviewers to the team
        selected_reviewers.each do |reviewer|
        # Prevent duplicate mappings
        exists = ResponseMap.exists?(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: team.id,
            type: mapping_type
        )
    
        next if exists
    
        # Create the mapping
        ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: team.id,
            type: mapping_type
        )
        created_count += 1
        end
    
        # Return success message
        {
        success: true,
        message: "Assigned #{created_count} reviewers to team ##{team.id}."
        }
    end
    
    # Generates peer review mappings in a circular staggered fashion for both individual and team-based assignments
    def generate_peer_review_strategy(assignment, options = {})
        # Retrieve the number of reviews each student/team should perform (default: 3)
        num_reviews = options[:num_reviews_per_student]&.to_i || 3

        # Optional strategy param, useful for logging or response messages
        strategy = options[:strategy] || 'peer_review'

        # Choose reviewer pool and mapping type based on assignment configuration
        if assignment.has_teams
            # If the assignment uses teams, fetch all teams as reviewers
            reviewers = assignment.teams.to_a.shuffle

            # Use STI type for team-based reviews
            mapping_type = 'ResponseMap'
        else
            # If the assignment is individual, fetch all participants as reviewers
            reviewers = assignment.participants.to_a.shuffle

            # Use base mapping type for individual review mappings
            mapping_type = 'ResponseMap'
        end

        # Prevent mapping generation if there are fewer than 2 reviewers
        return { success: false, message: 'Not enough reviewers to generate peer review mappings.' } if reviewers.size < 2

        # Counter to track how many review mappings were created
        created_count = 0

        # Core peer review logic: circular staggered assignment
        # For each reviewer (team or participant), assign the next N peers as reviewees
        reviewers.each_with_index do |reviewer, index|
            assigned_reviewees = []  # Tracks reviewees assigned to this reviewer
            offset = 1               # Start from the next element in the circle

            while assigned_reviewees.size < num_reviews
            # Use modular arithmetic to wrap around the list circularly
            reviewee = reviewers[(index + offset) % reviewers.size]
            offset += 1

            # Skip self-review scenarios:
            # - For teams: ensure a team does not review itself
            # - For individuals: ensure a student doesn't review their own work
            if assignment.has_teams
                next if reviewer.id == reviewee.id
            else
                next if reviewer.user_id == reviewee.user_id
            end

            # Avoid assigning the same reviewee twice to the same reviewer
            next if assigned_reviewees.include?(reviewee)

            # Add to current list of reviewees
            assigned_reviewees << reviewee
            end

            # Create review mappings for each valid reviewer-reviewee pair
            assigned_reviewees.each do |reviewee|
            # Check if the mapping already exists to prevent duplicates
            already_exists = ResponseMap.exists?(
                reviewed_object_id: assignment.id,
                reviewer_id: reviewer.id,
                reviewee_id: reviewee.id,
                type: mapping_type
            )

            # Create new mapping if it does not already exist
            unless already_exists
                ResponseMap.create!(
                reviewed_object_id: assignment.id,
                reviewer_id: reviewer.id,
                reviewee_id: reviewee.id,
                type: mapping_type
                )
                created_count += 1
            end
            end
        end

        # Return a success message along with the count of mappings created
        {
            success: true,
            message: "Created #{created_count} peer review mappings using strategy '#{strategy}'."
        }
        end

        def self.find_available_metareviewer(review_mapping, assignment_id)
            assignment = Assignment.find(review_mapping.reviewed_object_id)
            all_participants = Participant.where(assignment_id: assignment.id)
        
            all_participants.find do |participant|
              # Avoid self-review and already assigned metareview
              participant.id != review_mapping.reviewer_id &&
                !MetareviewResponseMap.exists?(
                  reviewed_object_id: review_mapping.id,
                  reviewer_id: participant.id
                )
            end
          end
              
        
  end
  
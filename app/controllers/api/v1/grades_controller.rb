class Api::V1::GradesController < ApplicationController
    include GradesHelper
    before_action :action_allowed
    before_action :set_team_and_assignment_via_participant, only: [:edit, :update, :instructor_review]
    before_action :set_participant_and_team_via_assignment, only: [:view_our_scores, :view_my_scores]

    def action_allowed
        unless check_permission(action_name)
            render json: { error: "You do not have permission to perform this action." }, status: :forbidden
        end
    end

    # index (GET /api/v1/grades/:id/view_all_scores)
    # returns all review scores and computed heatmap data for the given assignment (instructor/TA view).
    def view_all_scores    
        @assignment = Assignment.find(params[:assignment_id])
        participant_scores = {}
        team_scores = {}
        
        if params[:participant_id]
            @participant = AssignmentParticipant.find(params[:participant_id])
            participant_scores = get_my_scores_data
        end 

        if params[:team_id]
            @team = AssignmentTeam.find(params[:team_id])
            team_scores = get_our_scores_data
        end

        
        render json: {
            team_scores: team_scores,
            participant_scores: participant_scores
        }
    end


    # view_our_scores (GET /api/v1/grades/:assignment_id/view_our_scores)
    # similar to view but scoped to the requesting student’s own team.
    # It returns the same heatmap data with reviewer identities removed, plus the list of review items.
    # renders JSON with scores, assignment, averages.
    # This meets the student’s need to see heatgrids for their team only (with anonymous reviewers) and the associated items.
    def view_our_scores
        render json: get_our_scores_data
    end

    def view_my_scores
        render json: get_my_scores_data
    end


    # edit (GET /api/v1/grades/:participant_id/edit)
    # provides data for the grade-assignment interface.
    # Given an AssignmentParticipant ID, it looks up the participant and its assignment, gathers the full list of items 
    # (via a helper like list_questions(assignment)), and computes existing peer-review scores for those items.
    # It then returns JSON including the participant, assignment, items, and current scores.
    # This lets the front end display an interface where an instructor can assign a grade and feedback (score breakdown) to that submission.
    def edit
        items = list_items(@assignment)
        scores = {}
        scores[:my_team] = get_our_scores_data
        scores[:my_own] = get_my_scores_data
        render json: {
        participant: @participant,
        assignment: @assignment,
        items: items,
        scores: scores
        }
    end


    # update (PATCH /api/v1/grades/:participant_id/update)
    # saves an instructor’s grade and feedback for a team submission.
    # The method finds the AssignmentParticipant, gets its team, and sets team.grade_for_submission = params[:grade_for_submission] and 
    # team.comment_for_submission = params[:comment_for_submission]. It then saves the team and returns a success response 
    # (for example, instructing the UI to reload the team view). This implements “assign score & give feedback” for instructor.
    def update
        # team = @participant.team
        @team.grade_for_submission = params[:grade_for_submission]
        @team.comment_for_submission = params[:comment_for_submission]
        if @team.save
        render json: { message: 'Team grade and comment updated successfully.' }, status: :ok
        else
        render json: { error: 'Failed to update team grade or comment.' }, status: :unprocessable_entity
        end
    end


    # instructor_review (GET /api/v1/grades/:id/instructor_review)
    # helps the instructor begin grading or re-grading a submission.
    # It finds or creates the appropriate review mapping for the given participant and returns JSON indicating whether to go to 
    # Response#new (no review exists yet) or Response#edit (review already exists).
    # This supports the instructor’s ability to open or edit a review for a student’s submission.
    def instructor_review
        reviewer = AssignmentParticipant.find_or_create_by!(user_id: current_user.id, parent_id: @assignment.id, handle: current_user.name)         

        mapping = ReviewResponseMap.find_or_create_by!(
        reviewed_object_id: @assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: @team.id
        )

        existing_response = Response.find_by(map_id: mapping.id)
        action = existing_response.present? ? 'edit' : 'new'

        render json: {
        map_id: mapping.id,
        response_id: existing_response&.id,
        redirect_to: "/response/#{action}/#{mapping.id}"
        }
    end

    private

    def set_team_and_assignment_via_participant
        @participant = AssignmentParticipant.find(params[:participant_id])
        unless @participant
        render json: { error: 'Participant not found' }, status: :not_found
        return
        end
        @team = @participant.team
        unless @team
        render json: { error: 'Team not found' }, status: :not_found
        return
        end
        @assignment = @participant.assignment
    end

    # only called when a student wants to review its grades
    def set_participant_and_team_via_assignment
        @participant = AssignmentParticipant.find_by(parent_id: params[:assignment_id], user_id: current_user.id)
        unless @participant
        render json: { error: 'Participant not found' }, status: :not_found
        return
        end
        @team = @participant.team
        unless @team
        render json: { error: 'Team not found' }, status: :not_found
        return
        end
        @assignment = @participant.assignment
    end

    def check_permission(action)
        role = current_user.role.name
        allowed_roles = {
        'view_our_scores' => ['Student', 'Instructor', 'Teaching Assistant','Super Administrator'],
        'view_my_scores' => ['Student', 'Instructor', 'Teaching Assistant','Super Administrator'],
        'view_all_scores' => ['Instructor', 'Teaching Assistant','Super Administrator'],
        'edit' => ['Instructor','Super Administrator'],
        'update' => ['Instructor', 'Super Administrator'],
        'instructor_review' => ['Instructor', 'Teaching Assistant', 'Super Administrator'],
        'get_response_scores' => ['Student','Super Administrator']
        }
        allowed_roles[action]&.include?(role)
    end
    
    def get_our_scores_data
        reviews_of_our_work_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: @team.id).to_a
        reviews_of_our_work = get_heatgrid_data_for(reviews_of_our_work_maps)
        avg_score_of_our_work = @team.aggregate_review_grade

        {
            reviews_of_our_work: reviews_of_our_work,
            avg_score_of_our_work: avg_score_of_our_work
        }
    end

    def get_my_scores_data
        # the set of review maps that my team members used to review me
        reviews_of_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: @participant.id).to_a 

        # the set of review maps that I used to review my team members
        reviews_by_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: @participant.id).to_a
        
        reviews_of_me = get_heatgrid_data_for(reviews_of_me_maps)

        reviews_by_me = get_heatgrid_data_for(reviews_by_me_maps)

        # Fetch all review response maps where the current participant is the reviewer and the reviewed object is the current assignment.
        my_reviews_of_other_teams_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: @participant.id)

        # the maps that the authors I (the participant) reviewed used to give feedback on my reviews
        feedback_from_my_reviewees_maps = []
           
        my_reviews_of_other_teams_maps.each do |map|
            feedback_from_my_reviewees_maps << FeedbackResponseMap.find_by(reviewed_object_id: map.id, reviewee_id: @participant.id)           
        end

        feedback_scores_from_my_reviewees = get_heatgrid_data_for(feedback_from_my_reviewees_maps)

        avg_score_from_my_teammates = @participant.aggregate_teammate_review_grade(reviews_of_me_maps) 
        avg_score_to_my_teammates = @participant.aggregate_teammate_review_grade(reviews_by_me_maps) 
        avg_score_from_my_authors = @participant.aggregate_teammate_review_grade(feedback_from_my_reviewees_maps) 

        {
            reviews_of_me: reviews_of_me,
            reviews_by_me: reviews_by_me,
            author_feedback_scores: feedback_scores_from_my_reviewees,
            avg_score_from_my_teammates: avg_score_from_my_teammates,
            avg_score_to_my_teammates: avg_score_to_my_teammates,
            avg_score_from_my_authors: avg_score_from_my_authors
        }
    end

    def get_heatgrid_data_for(maps)
        # Initialize a hash to store scores grouped by review rounds
        reviewee_scores = {}
        return if maps.empty?

        # check if the assignment uses different rubrics for each round
        if @assignment.varying_rubrics_by_round?
            # Retrieve all round numbers that have distinct questionnaires
            rounds = @assignment.review_rounds(maps.first.questionnaire_type)

            rounds.each do |round|
                # Create a symbol like :Review-Round-1 or :TeammateReview-Round-2
                round_symbol = ("#{maps.first.questionnaire_type}-Round-#{round}").to_sym

                # Initialize the array to hold scores for the current round
                reviewee_scores[round_symbol] = []

                # Go through each response map (i.e., reviewer mapping)
                maps.each_with_index do |map, index|
                    # Find the most recent submitted response for the current round
                    submitted_round_response = map.responses.select do |r|
                        r.round == round && r.is_submitted && r.map_id == map.id
                    end.last

                    # Skip if no valid response was submitted
                    next if submitted_round_response.nil?

                    # Go through each score in the submitted response
                    submitted_round_response.scores.each_with_index do |score, newIndex|
                        # Initialize sub-array if it doesn't exist
                        reviewee_scores[round_symbol][newIndex] ||= []

                        # Add the score's answer, optionally anonymizing reviewer name                        
                        reviewee_scores[round_symbol][newIndex] << get_answer(score, index)
                    end
                end

                reviewee_scores[round_symbol].each_with_index do |scores_array, idx|
                    # Sort each question's answers array by reviewer_name and reviwee_name 
                    reviewee_scores[round_symbol][idx] = scores_array.sort_by { |ans| [ans[:reviewer_name].downcase , ans[:reviewee_name].downcase] }
                end
            end

        end

        # Return the organized hash of scores grouped by round
        return reviewee_scores
    end

    def get_answer(score, index)
        # Determine the name or label to show for the reviewer
        reviewer_name = if current_user_has_all_heatgrid_data_privileges?(@assignment)
                           score&.response&.reviewer&.fullname # Show the actual reviewer's name
                        else
                            "Participant #{index+1}" # Show generic label (e.g., Participant 1)
                        end
        
        # useful in case of reviews done by reviews_by_me (reviews given by a user to its teammates)
        # in that case we will need reviewee's name instead of reviewer name because the reviewer will be the user itself.
        reviewee_name = score&.response&.reviewee&.fullname                        

        #Return particular score/answer information
        return {
            id: score.id,
            item_id:score.item_id,
            answer:score.answer,
            comments:score.comments,
            reviewer_name: reviewer_name,
            reviewee_name: reviewee_name
        }
    end 
end
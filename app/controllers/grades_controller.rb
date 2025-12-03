class GradesController < ApplicationController
    include GradesHelper

    def action_allowed?
        case params[:action]
        when 'view_our_scores','view_my_scores'
            set_participant_and_team_via_assignment
            current_user_is_assignment_participant?(params[:assignment_id])
        when 'view_all_scores', 'get_review_tableau_data'
            current_user_teaching_staff_of_assignment?(params[:assignment_id])
        when 'edit', 'assign_grade', 'instructor_review'
            set_team_and_assignment_via_participant
            current_user_instructs_assignment?(@assignment)
        else
            render json: { error: "You do not have permission to perform this action." }, status: :forbidden
        end
    end

    # index (GET /api/v1/grades/:assignment_id/view_all_scores)
    # returns all review scores and computed heatmap data for the given assignment (instructor/TA view).
    def view_all_scores    
        @assignment = Assignment.find(params[:assignment_id])
        participant_scores = []
        team_scores = []
        
        @assignment.participants.each do |participant|
            participant_scores.push(get_my_scores_data(participant))
        end
        
        @assignment.teams.each do |team|
            team_scores.push(get_our_scores_data(team))
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
        render json: get_our_scores_data(@team)
    end

    # (GET /api/v1/grades/:assignment_id/view_my_scores)
    # similar to view but scoped to the requesting student’s own scores given by its teammates and also .
    def view_my_scores
        render json: get_my_scores_data(@participant)
    end


    # (GET /api/v1/grades/:assignment_id/:participant_id/get_review_tableau_data)
    # Given an AssignmentParticipant ID, gather and return all reviews completed by that participant for the corresponding assignment.
    def get_review_tableau_data
        responses_by_round = {}
        begin
            # Determine all questionnaires used as part of this assignment, grouped by the round in which they are used.
            AssignmentQuestionnaire.where("assignment_id = " + params[:assignment_id]).find_each do |pairing|
                round_id = pairing[:used_in_round]
                rubric_id = pairing[:questionnaire_id]

                # If this round has not been recorded yet, record it.
                if !responses_by_round.key?(round_id)
                    responses_by_round[round_id] = {}
                end
                # If this questionnaire has not been recorded yet, record it.
                if !responses_by_round[round_id].key?(rubric_id)
                    # Items (the "questions") are always the same across responses of the same rubric.
                    # Initialize them into a hash using a helper function.
                    responses_by_round[round_id] = get_items_from_questionnaire(rubric_id)
                end
            end

            response_mapping_condition = "reviewed_object_id = " + params[:assignment_id] + " AND reviewer_id = " + params[:participant_id]
            ReviewResponseMap.where(response_mapping_condition).find_each do |mapping|
                Response.where("map_id = " + mapping[:id].to_s).find_each do |response|

                    # response = Response.find_by(map_id: mapping[:id])

                    if response == nil
                        # If, for some reason, there is no response with this mapping id, move on to the next mapping id.
                        next
                    end

                    response_id = response[:id]
                    round_id = response[:round]

                    if !responses_by_round.key?(round_id)
                        # If, for some reason, there is no questionnaire associated with the given round, move on to the next mapping id.
                        next
                    end

                    # Record this response's values and comments, one pair for each item in the corresponding questionnaire.
                    responses_by_round[round_id].each_key do |item_id|
                        response_answer = Answer.find_by(item_id: item_id, response_id: response_id)
                        responses_by_round[round_id][item_id][:answers][:values].append(response_answer[:answer])
                        responses_by_round[round_id][item_id][:answers][:comments].append(response_answer[:comments])
                    end
                end
            end

            # Get participant and user information for the response
            participant = AssignmentParticipant.find(params[:participant_id])
            assignment = Assignment.find(params[:assignment_id])

            # Return JSON containing all answer values and comments associated with this reviewer and for this assignment.
            render json: {
                responses_by_round: responses_by_round,
                participant: {
                    id: participant.id,
                    user_id: participant.user_id,
                    user_name: participant.user.name,
                    full_name: participant.user.full_name,
                    handle: participant.handle
                },
                assignment: {
                    id: assignment.id,
                    name: assignment.name
                }
            }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Participant or assignment not found" }, status: :not_found
        rescue StandardError => e
          render json: { error: "Internal server error" }, status: :internal_server_error
        end
    end

    # A helper function which, given a questionnaire id, returns a hash keyed by the ids of that questionnaire's items.
    # The values of the hash include the description (usually a question) of the item, and an empty hash for including responses.
    def get_items_from_questionnaire(questionnaire_id)
        questionnaire = Questionnaire.find_by(id: questionnaire_id)
        item_data = {
            min_answer_value: questionnaire[:min_question_score],
            max_answer_value: questionnaire[:max_question_score],
            items: {}
        }
        Item.where("questionnaire_id = " + questionnaire_id.to_s).find_each do |item|
            item_data[:items][item[:id]] = {
                description: item[:txt],
                question_type: item[:question_type],
                answers: {
                    values: [],
                    comments: []
                }
            }
        end
        return item_data
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
        scores[:my_team] = get_our_scores_data(@team)
        scores[:my_own] = get_my_scores_data(@participant)
        render json: {
        participant: @participant,
        assignment: @assignment,
        items: items,
        scores: scores
        }
    end


    # assign_grade (PATCH /api/v1/grades/:participant_id/assign_grade)
    # saves an instructor’s grade and feedback for a team submission.
    # The method sets team.grade_for_submission and team.comment_for_submission. 
    # This implements “assign score & give feedback” functionality for instructor.
    def assign_grade
        # team = @participant.team
        @team.grade_for_submission = params[:grade_for_submission]
        @team.comment_for_submission = params[:comment_for_submission]
        if @team.save
            render json: { message: "Grade and comment assigned to team #{@team.name} successfully." }, status: :ok
        else
            render json: { error: "Failed to assign grade or comment to team #{@team.name}." }, status: :unprocessable_entity
        end
    end


    # instructor_review (GET /api/v1/grades/:participant_id/instructor_review)
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

    # helper method used when participant_id is passed as a paramater. this will be helpful in case of instructor/TA view 
    # as they need participant id to view their scores or assign grade. It will take the participant id (i.e. AssignmentParticipant ID) to set 
    # the team and assignment variables which are used inside other methods like edit, update, assign_grade
    def set_team_and_assignment_via_participant
        @participant = AssignmentParticipant.find(params[:participant_id])
        unless @participant
            return { error: 'Participant not found for this assignment' , status: :not_found}
        end
        @team = @participant.team
        unless @team
            return { error: 'Team not found for this assignment' , status: :not_found}
        end
        @assignment = @participant.assignment
    end

    # helper method used when participant_id is passed as a paramater. this will be helpful in case of student view 
    # It will take the assignment id and the current user's id to set the participant and team variables which are used inside other methods
    # like view_our_scores and view_my_scores
    def set_participant_and_team_via_assignment
        @participant = AssignmentParticipant.find_by(parent_id: params[:assignment_id], user_id: current_user.id)
        unless @participant
            return { error: 'Participant not found' , status: :not_found}
        end
        @team = @participant.team
        unless @team
            return { error: 'Team not found' , status: :not_found}
        end
        @assignment = @participant.assignment
    end

    
    # returns the heatgrid data required for a team to view their scores and average score of their work for an assignment
    def get_our_scores_data(team)
        reviews_of_our_work_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: team.id).to_a
        reviews_of_our_work = get_heatgrid_data_for(reviews_of_our_work_maps)
        avg_score_of_our_work = team.aggregate_review_grade

        {
            team_details: team,
            reviews_of_our_work: reviews_of_our_work,
            avg_score_of_our_work: avg_score_of_our_work
        }
    end

    # returns the heatgrid data required for a participant to view their scores and average score of their work for an assignment
    # the data includes the scores given by their teammates as well as the scores given by the authors the participant reviewed
    def get_my_scores_data(participant)
        # the set of review maps that my team members used to review me
        reviews_of_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: participant.id).to_a 

        # the set of review maps that I used to review my team members
        reviews_by_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: participant.id).to_a
        
        reviews_of_me = get_heatgrid_data_for(reviews_of_me_maps)

        reviews_by_me = get_heatgrid_data_for(reviews_by_me_maps)

        # Fetch all review response maps where the current participant is the reviewer and the reviewed object is the current assignment.
        my_reviews_of_other_teams_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: participant.id)

        # the maps that the authors I (the participant) reviewed used to give feedback on my reviews
        feedback_from_my_reviewees_maps = []

        # Map each review to its corresponding FeedbackResponseMap, may return nil if not found
        # Then remove all nil entries using .compact before adding them to the main array
        feedback_from_my_reviewees_maps += my_reviews_of_other_teams_maps.map do |map|
            FeedbackResponseMap.find_by(reviewed_object_id: map.id, reviewee_id: participant.id)
        end.compact

        feedback_scores_from_my_reviewees = get_heatgrid_data_for(feedback_from_my_reviewees_maps)

        avg_score_from_my_teammates = participant.aggregate_teammate_review_grade(reviews_of_me_maps) 
        avg_score_to_my_teammates = participant.aggregate_teammate_review_grade(reviews_by_me_maps) 
        avg_score_from_my_authors = participant.aggregate_teammate_review_grade(feedback_from_my_reviewees_maps) 

        {
            participant_details: participant,
            reviews_of_me: reviews_of_me,
            reviews_by_me: reviews_by_me,
            author_feedback_scores: feedback_scores_from_my_reviewees,
            avg_score_from_my_teammates: avg_score_from_my_teammates,
            avg_score_to_my_teammates: avg_score_to_my_teammates,
            avg_score_from_my_authors: avg_score_from_my_authors
        }
    end

    # it returns the heatgrid data for a collection of maps (ReviewResponseMap/FeedbackResponseMap/TeammateReviewResponseMap)
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
                    reviewee_scores[round_symbol][idx] = scores_array.sort_by { |answer| [answer[:reviewer_name].downcase , answer[:reviewee_name].downcase] }
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
            txt: score.item.txt,
            answer:score.answer,
            comments:score.comments,
            reviewer_name: reviewer_name,
            reviewee_name: reviewee_name
        }
    end 
end
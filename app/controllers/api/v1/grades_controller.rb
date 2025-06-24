class Api::V1::GradesController < ApplicationController
    include GradesHelper

    # action :set_participant_and_assignment, only: [:edit, :update, :instructor_review]

    def action_allowed
        action = params[:requested_action]
        allowed = check_permission(action)
        render json: { allowed: allowed }, status: allowed ? :ok : :forbidden
    end


    # index (GET /api/v1/grades/:id/view_scores)
    # returns all review scores and computed heatmap data for the given assignment (instructor/TA view).
    # The controller should call a helper like get_data_for_heat_map(id) and then render JSON including the 
    # per-participant and per-team scores, the assignment info, and computed averages (overall and per-team).
    # This satisfies the requirement for instructors to see heatgrids of all reviews and rounds for each submission.
    def view_scores
        assignment = Assignment.find(params[:assignment_id])
        data = get_data_for_heat_map(assignment)
        render json: {
        assignment: assignment,
        scores: data[:scores],
        items: data[:items],
        averages: data[:averages],
        # answers: data[:answers],
        message:"hello world",
        assignment_id: params[:assignment_id]
        }
    end


    # student_view (GET /api/v1/grades/:id/student_view)
    # similar to view but scoped to the requesting student’s own team.
    # It returns the same heatmap data with reviewer identities removed, plus the list of review questions.
    # In code this calls get_data_for_heat_map(id), then does @scores[:participants] = hide_reviewers_from_student, and 
    # renders JSON with scores, assignment, averages, and questions.
    # This meets the student’s need to see heatgrids for their team only (with anonymous reviewers) and the associated questions.
    def student_view
        assignment = Assignment.find(params[:assignment_id])
        scores, averages = GradesHelper.get_data_for_heat_map(assignment.id)
        scores[:participants] = GradesHelper.hide_reviewers_from_student(scores[:participants], current_user.id)
        questions = GradesHelper.list_questions(assignment)
        render json: {
        assignment: assignment,
        scores: scores,
        averages: averages,
        questions: questions
        }
    end


    # # edit (GET /api/v1/grades/:id/edit)
    # # provides data for the grade-assignment interface.
    # # Given an AssignmentParticipant ID, it looks up the participant and its assignment, gathers the full list of questions 
    # # (via a helper like list_questions(assignment)), and computes existing peer-review scores for those questions.
    # # It then returns JSON including the participant, assignment, questions, and current scores.
    # # This lets the front end display an interface where an instructor can assign a grade and feedback (score breakdown) to that submission.
    def edit
        questions = GradesHelper.list_questions(@assignment)
        scores = Response.review_grades(@participant, questions)
        render json: {
        participant: @participant,
        assignment: @assignment,
        questions: questions,
        scores: scores
        }
    end


    # # update (PATCH /api/v1/grades/:participant_id/update/:grade_for_submission)
    # # saves an instructor’s grade and feedback for a team submission.
    # # The method finds the AssignmentParticipant, gets its team, and sets team.grade_for_submission = params[:grade_for_submission] and 
    # # team.comment_for_submission = params[:comment_for_submission]. It then saves the team and returns a success response 
    # # (for example, instructing the UI to reload the team view). This implements “assign score & give feedback” for instructor.
    def update
        team = @participant.team
        team.grade_for_submission = params[:grade_for_submission]
        team.comment_for_submission = params[:comment_for_submission]
        if team.save
        render json: { message: 'Team grade and comment updated successfully.' }, status: :ok
        else
        render json: { error: 'Failed to update team grade or comment.' }, status: :unprocessable_entity
        end
    end


    # # instructor_review (GET /api/v1/grades/:id/instructor_review)
    # # helps the instructor begin grading or re-grading a submission.
    # # It finds or creates the appropriate review mapping for the given participant and returns JSON indicating whether to go to 
    # # Response#new (no review exists yet) or Response#edit (review already exists).
    # # This supports the instructor’s ability to open or edit a review for a student’s submission.
    def instructor_review
        participant = AssignmentParticipant.find_by(id: params[:assignment_id])
        return render json: { error: 'Participant not found' }, status: :not_found unless participant

        assignment = participant.assignment
        reviewer = AssignmentParticipant.find_or_create_by(user_id: current_user.id, parent_id: assignment.id) do |p|
        #
        p.handle = AssignmentParticipant::generate_anonymous_handle(assignment.id)
        end

        mapping = ReviewResponseMap.find_or_create_by(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: participant.team.id
        )

        existing_response = Response.find_by(map_id: mapping.id)
        action = existing_response.present? ? 'edit' : 'new'

        render json: {
        map_id: mapping.id,
        response_id: existing_response&.id,
        redirect_to: "/response/#{action}/#{mapping.id}"
        }
    end


    # # action_allowed (GET /api/v1/grades/:action/action_allowed)
    # # enforces permissions for actions like view_team. For example, it only allows students to call view_team on their own team’s participant ID.
    # # The method checks the current user’s role and the requested action and returns {allowed: true/false} in JSON.
    # # This ensures, for instance, that a student cannot view another team’s heatmap.
    def action_allowed
        action = params[:requested_action]
        allowed = check_permission(action)
        render json: { allowed: allowed }, status: allowed ? :ok : :forbidden
    end




    private

    def set_participant_and_assignment
        @participant = AssignmentParticipant.find_by(id: params[:assignment_id])
        unless @participant
        render json: { error: 'Participant not found' }, status: :not_found
        return
        end
        @assignment = @participant.assignment
    end

    def check_permission(action)
        role = current_user.role.name
        allowed_roles = {
        'view_team' => ['Student', 'Instructor', 'Teaching Assistant'],
        'view' => ['Instructor', 'Teaching Assistant'],
        'edit' => ['Instructor'],
        'update' => ['Instructor'],
        'instructor_review' => ['Instructor', 'Teaching Assistant']
        }
        allowed_roles[action]&.include?(role)
    end
end
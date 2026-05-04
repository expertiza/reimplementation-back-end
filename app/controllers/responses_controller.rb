# frozen_string_literal: true

class ResponsesController < ApplicationController
  before_action :set_response, only: [:update, :submit, :unsubmit, :destroy]

  # Authorization: determines if current user can perform the action
  def action_allowed?
    case action_name
    when 'create'
      map_id = params[:response_map_id] || params[:map_id]
      map = ResponseMap.find_by(id: map_id)
      return false unless map && map.assignment

      # Reviewer, teaching staff (instructor/TA), or admin ancestor of instructor
      response_owner?(map) ||
        current_user_teaching_staff_of_assignment?(map.assignment.id) ||
        parent_admin_for_assignment?(map.assignment)

    when 'update', 'submit'
      resp = Response.find_by(id: params[:id])
      return false unless resp && resp.response_map&.assignment

      current_user_owns_response?(resp) ||
        current_user_teaching_staff_of_assignment?(resp.response_map.assignment.id) ||
        parent_admin_for_response?(resp)

    when 'unsubmit', 'destroy'
      resp = Response.find_by(id: params[:id])
      return false unless resp && resp.response_map&.assignment

      current_user_teaching_staff_of_assignment?(resp.response_map.assignment.id) ||
        parent_admin_for_response?(resp)

    else
      false
    end
  end

  # POST /responses
  def create
    @response_map = ResponseMap.find_by(id: params[:response_map_id] || params[:map_id])
    return render json: { error: 'ResponseMap not found' }, status: :not_found unless @response_map

    @response = Response.new(
      map_id: @response_map.id,
      is_submitted: false,
      created_at: Time.current
    )

    if @response.save
      render json: { message: "#{response_label} started successfully", response: @response }, status: :created
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id
  # Reviewer edits existing draft (still unsubmitted)
  def update
    return render json: { error: "#{response_label} not found" }, status: :not_found unless @response
    return render json: { error: 'forbidden' }, status: :forbidden if @response.is_submitted?

    if @response.update(response_params)
      render json: { message: "#{response_label} saved successfully", response: @response }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/submit
  # Lock the response and calculate final score
  def submit
    return render json: { error: "#{response_label} not found" }, status: :not_found unless @response
    if @response.is_submitted?
      return render json: { error: "#{response_label} has already been submitted" }, status: :unprocessable_entity
    end
    response_map = @response.response_map
    # Check deadline
    unless DueDate.assignment_open_for?(action: :submission, assignment: response_map&.assignment, topic: reviewee_topic_for(response_map))
      return render json: { error: "#{response_label} deadline has passed" }, status: :forbidden
    end

    # Lock response
    @response.is_submitted = true

    # Calculate score via ScorableHelper
    total_score = @response.aggregate_questionnaire_score

    if @response.save
      render json: {
        message: "#{response_label} submitted and scored successfully",
        response: @response,
        total_score: total_score
      }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/unsubmit
  # Instructor/Admin allows a submitted response to be reopened for editing.
  def unsubmit
    return render json: { error: "#{response_label} not found" }, status: :not_found unless @response

    if @response.is_submitted?
      if @response.update(is_submitted: false)
        render json: { message: "#{response_label} reopened for editing. The reviewer can now make changes.", response: @response }, status: :ok
      else
        render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    else
      render json: { error: "This #{response_label.downcase} is not submitted, so it cannot be reopened" }, status: :unprocessable_entity
    end
  end

  # DELETE /responses/:id
  # Instructor/Admin deletes a response
  def destroy
    return render json: { error: "#{response_label} not found" }, status: :not_found unless @response

    @response.destroy
    head :no_content
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_response
    @response = Response.find_by(id: params[:id])
  end

  def response_params
    # Keep generic PATCH narrowly scoped to draft editing. The map binding and
    # submitted state are controlled by dedicated endpoints (`create`, `submit`,
    # `unsubmit`) so reviewers cannot reattach a response to a different map or
    # self-lock a draft through the update action.
    params.require(:response).permit(
      :additional_comment,
      scores_attributes: [:id, :item_id, :answer, :comments]
    )
  end

  def current_user_owns_response?(resp = @response)
    return false unless resp&.map && current_user

    reviewer_owned_by_current_user?(resp.map.reviewer)
  end

  # Keep these wrappers local to this controller for now. The shared primitives
  # (`find_assignment_instructor`, `current_user_ancestor_of?`, role checks) are
  # already provided by Authorization. The policy here is response-specific:
  # allow an Administrator only when they are an ancestor of the assignment's
  # instructor, which is the rule used to reopen/delete responses and to let an
  # admin act on a response map during creation.
  def parent_admin_for_response?(response) # TODO: move this to generic parent-admin helper if we find more use cases
    assignment = response&.response_map&.assignment
    parent_admin_for_assignment?(assignment)
  end

  def parent_admin_for_assignment?(assignment)  # TODO: move this to generic parent-admin helper if we find more use cases. mention the admin who created the instructor i
    instructor = assignment && find_assignment_instructor(assignment)
    user_logged_in? && current_user_is_a?('Administrator') && instructor && current_user_ancestor_of?(instructor)
  end

  def response_owner?(map)
    user_logged_in? && reviewer_owned_by_current_user?(map.reviewer)
  end

  # Controller-level message helper for the human-readable response type used in
  # API messages, such as "Review" or "Teammate Review".
  def response_label
    return @response.rubric_label if @response

    map_label = @response_map&.response_map_label
    map_label.presence || 'Response'
  end

  # Keep response-map-to-topic lookup here; deadline comparison belongs on DueDate.
  def reviewee_topic_for(response_map)
    assignment = response_map&.assignment
    reviewee = response_map&.reviewee
    return nil unless assignment && reviewee.respond_to?(:signed_up_teams)

    signup = reviewee.signed_up_teams
                    .joins(:project_topic)
                    .find_by(project_topics: { assignment_id: assignment.id })
    signup&.project_topic
  end

  def reviewer_owned_by_current_user?(reviewer)
    # Response maps point to Participant records, but authorization is based on
    # the logged-in User. Compare through `reviewer.user_id` rather than the
    # participant's own id so the actual reviewer can edit/submit their draft.
    reviewer&.user_id == current_user.id
  end
end

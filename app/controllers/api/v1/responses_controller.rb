class Api::V1::ResponsesController < ApplicationController
  before_action :authorize_show_calibration_results, only: %i[show_calibration_results_for_student]
  before_action :set_response, only: %i[update delete view]

  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    set_content
  end
  def new
    assign_action_parameters
    set_content(true)
    if @assignment
      @stage = @assignment.current_stage(SignedUpTeam.topic_id(@participant.parent_id, @participant.user_id))
    end
    # Because of the autosave feature and the javascript that sync if two reviewing windows are opened
    # The response must be created when the review begin.
    # So do the answers, otherwise the response object can't find the questionnaire when the user hasn't saved his new review and closed the window.
    # A new response has to be created when there hasn't been any reviews done for the current round,
    # or when there has been a submission after the most recent review in this round.
    @response = @response.create_or_get_response(@map, @current_round.to_i)
    questions = sort_questions(@questionnaire.questions)
    store_total_cake_score
    init_answers(questions)
    render action: 'response'
  end
  def create
    map_id = params[:id]
    unless params[:map_id].nil?
      map_id = params[:map_id]
    end # pass map_id as a hidden field in the review form
    @map = ResponseMap.find(map_id)
    if params[:review][:questionnaire_id]
      @questionnaire = Questionnaire.find(params[:review][:questionnaire_id])
      @round = params[:review][:round]
    else
      @round = nil
    end
    is_submitted = (params[:isSubmit] == 'Yes')
    # There could be multiple responses per round, when re-submission is enabled for that round.
    # Hence we need to pick the latest response.
    @response = Response.where(map_id: @map.id, round: @round.to_i).order(created_at: :desc).first
    if @response.nil?
      @response = Response.create(map_id: @map.id, additional_comment: params[:review][:comments],
                                  round: @round.to_i, is_submitted: is_submitted)
    end
    was_submitted = @response.is_submitted

    # ignore if autoupdate try to save when the response object is not yet created.s
    @response.update(additional_comment: params[:review][:comments], is_submitted: is_submitted)

    # :version_num=>@version)
    # Change the order for displaying questions for editing response views.
    questions = sort_questions(@questionnaire.questions)
    create_answers(params, questions) if params[:responses]
    msg = 'Your response was successfully saved.'
    error_msg = ''

    # only notify if is_submitted changes from false to true
    if (@map.is_a? ReviewResponseMap) && (!was_submitted && @response.is_submitted) && @response.significant_difference?
      @response.notify_instructor_on_difference
      @response.email
    end
    redirect_to controller: 'response', action: 'save', id: @map.map_id,
                return: params.permit(:return)[:return], msg: msg, error_msg: error_msg, review: params.permit(:review)[:review], save_options: params.permit(:save_options)[:save_options]
  end
  def edit
    assign_action_parameters
    @prev = Response.where(map_id: @map.id)
    @review_scores = @prev.to_a
    if @prev.present?
      @sorted = @review_scores.sort do |m1, m2|
        if m1.version_num.to_i && m2.version_num.to_i
          m2.version_num.to_i <=> m1.version_num.to_i
        else
          m1.version_num ? -1 : 1
        end
      end
      @largest_version_num = @sorted[0]
    end
    # Added for E1973, team-based reviewing
    @map = @response.map
    if @map.team_reviewing_enabled
      @response = Lock.get_lock(@response, current_user, Lock::DEFAULT_TIMEOUT)
      if @response.nil?
        response_lock_action
        return
      end
    end

  end
  def update

  end
  def destroy

  end

  # E2218: Method to initialize response and response map for update, delete and view methods
  def set_response
    @response = Response.find(params[:id])
    @map = @response.map
  end
end
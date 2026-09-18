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

  # index (GET /grades/:assignment_id/view_all_scores)
  # returns all review scores and computed heatmap data for the given assignment (instructor/TA view).
  def view_all_scores
    @assignment = Assignment.find(params[:assignment_id])
    participant_scores = []
    team_scores = []

    @assignment.participants.each do |participant|
      participant_scores.push(get_my_scores_data(participant))
    end

    # Preload team.users for all teams in one query to avoid N+1 inside get_team_scores.
    # Without this, each call to get_team_scores fires a separate `team.users` JOIN query
    # (one per team), which degrades linearly with the number of teams in the assignment.
    @assignment.teams.includes(:users).each do |team|
      team_scores.push(get_team_scores(team))
    end

    render json: {
      team_scores: team_scores,
      participant_scores: participant_scores
    }
  end


  # view_our_scores (GET /grades/:assignment_id/view_our_scores)
  # similar to view but scoped to the requesting student's own team.
  # It returns the same heatmap data with reviewer identities removed, plus the list of review items.
  # renders JSON with scores, assignment, averages.
  # This meets the student's need to see heatgrids for their team only (with anonymous reviewers) and the associated items.
  def view_our_scores
    render json: get_team_scores(@team)
  end

  # (GET /grades/:assignment_id/view_my_scores)
  # similar to view but scoped to the requesting student's own scores given by its teammates and also .
  def view_my_scores
    render json: get_my_scores_data(@participant)
  end

  # (GET /grades/:assignment_id/:participant_id/get_review_tableau_data)
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
            next unless response_answer
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
      render json: { error: e.message }, status: :internal_server_error
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


  # edit (GET /grades/:participant_id/edit)
  # provides data for the grade-assignment interface.
  # Given an AssignmentParticipant ID, it looks up the participant and its assignment, gathers the full list of items
  # (via a helper like list_questions(assignment)), and computes existing peer-review scores for those items.
  # It then returns JSON including the participant, assignment, items, and current scores.
  # This lets the front end display an interface where an instructor can assign a grade and feedback (score breakdown) to that submission.
  def edit
    items = list_items(@assignment)
    scores = {}
    scores[:my_team] = get_team_scores(@team)
    scores[:my_own] = get_my_scores_data(@participant)
    render json: {
      participant: @participant,
      assignment: @assignment,
      items: items,
      scores: scores
    }
  end


  # assign_grade (PATCH /grades/:participant_id/assign_grade)
  # saves an instructor's grade and feedback for a team submission.
  # The method sets team.grade_for_submission and team.comment_for_submission.
  # This implements "assign score & give feedback" functionality for instructor.
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
  # Helps the instructor begin grading or re-grading a submission.
  #
  # Older Expertiza flows returned UI redirect paths such as
  # `/response/new/:id`. This API-only controller instead returns the HTTP
  # method, path, and request payload the client should use against the
  # current `/responses` endpoints. That keeps GradesController decoupled from
  # any specific front-end routing while still exposing enough information for
  # the client to continue or start a review.
  def instructor_review
    reviewer = AssignmentParticipant.find_or_create_by!(user_id: current_user.id, parent_id: @assignment.id, handle: current_user.name)

    mapping = ReviewResponseMap.find_or_create_by!(
      reviewed_object_id: @assignment.id,
      reviewer_id: reviewer.id,
      reviewee_id: @team.id
    )

    existing_response = Response.find_by(map_id: mapping.id)
    request_contract =
      if existing_response.present? && !existing_response.is_submitted?
        {
          response_id: existing_response.id,
          request_method: 'PATCH',
          request_path: "/responses/#{existing_response.id}",
          request_payload: {}
        }
      else
        {
          response_id: nil,
          request_method: 'POST',
          request_path: '/responses',
          request_payload: { response_map_id: mapping.id }
        }
      end

    render json: {
      map_id: mapping.id,
      response_id: request_contract[:response_id],
      request_method: request_contract[:request_method],
      request_path: request_contract[:request_path],
      request_payload: request_contract[:request_payload]
    }
  end

  private

  # helper method used when participant_id is passed as a parameter. this will be helpful in case of instructor/TA view
  # as they need participant id to view their scores or assign grade. It will take the participant id (i.e. AssignmentParticipant ID) to set
  # the team and assignment variables which are used inside other methods like edit, update, assign_grade
  def set_team_and_assignment_via_participant
    @participant = AssignmentParticipant.find(params[:participant_id])
    unless @participant
      return { error: 'Participant not found for this assignment', status: :not_found }
    end
    @team = @participant.team
    unless @team
      return { error: 'Team not found for this assignment', status: :not_found }
    end
    @assignment = @participant.assignment
  end

  # helper method used when participant_id is passed as a parameter. this will be helpful in case of student view
  # It will take the assignment id and the current user's id to set the participant and team variables which are used inside other methods
  # like view_our_scores and view_my_scores
  def set_participant_and_team_via_assignment
    @participant = AssignmentParticipant.find_by(parent_id: params[:assignment_id], user_id: current_user.id)
    unless @participant
      return { error: 'Participant not found', status: :not_found }
    end
    @team = @participant.team
    unless @team
      return { error: 'Team not found', status: :not_found }
    end
    @assignment = @participant.assignment
  end

  # returns the heatgrid data required for a team to view their scores and average score of their work for an assignment
  def get_team_scores(team)
    reviews_of_our_work_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: team.id)
                                               .includes(responses: { scores: :item })
                                               .to_a
    reviews_of_our_work = get_reviews(reviews_of_our_work_maps)
    avg_score_of_our_work = team.aggregate_reviewer_score

    # Embed all team metadata directly in this response so the frontend can populate
    # team name, grade, submission links, and member list in a single API call.
    # Previously the frontend made 3+ follow-up requests:
    #   GET /participants/user/:id  →  GET /teams_participants/:id/list_participants
    #   →  GET /users/:id  (once per team member)
    # team.hyperlinks calls YAML.safe_load(submitted_hyperlinks) internally — no manual parsing.
    # team.users is a single JOIN through teams_participants (no N+1 — one query for all members).
    team_members = {
      team_name:        team.name,
      grade:            team.grade_for_submission,
      comment:          team.comment_for_submission,
      submission_links: team.hyperlinks,
      members:          team.users.map { |u| { name: u.full_name, username: u.name } }
    }

    {
      assignment_name:        @assignment.name,
      reviews_of_our_work:    reviews_of_our_work,
      avg_score_of_our_work:  avg_score_of_our_work,
      team_members:           team_members
    }
  end

  # returns the heatgrid data required for a participant to view their scores and average score of their work for an assignment
  # the data includes the scores given by their teammates as well as the scores given by the authors the participant reviewed
  def get_my_scores_data(participant)
    # the set of review maps that my team members used to review me
    reviews_of_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewee_id: participant.id)
                                                  .includes(responses: { scores: :item })
                                                  .to_a

    # the set of review maps that I used to review my team members
    reviews_by_me_maps = TeammateReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: participant.id)
                                                  .includes(responses: { scores: :item })
                                                  .to_a

    reviews_of_me = get_reviews(reviews_of_me_maps)

    reviews_by_me = get_reviews(reviews_by_me_maps)

    # Fetch all review response maps where the current participant is the reviewer and the reviewed object is the current assignment.
    my_reviews_of_other_teams_maps = ReviewResponseMap.where(reviewed_object_id: @assignment.id, reviewer_id: participant.id)

    # the maps that the authors I (the participant) reviewed used to give feedback on my reviews
    feedback_from_my_reviewees_maps = []

    # Map each review to its corresponding FeedbackResponseMap, may return nil if not found
    # Then remove all nil entries using .compact before adding them to the main array
    feedback_from_my_reviewees_maps += my_reviews_of_other_teams_maps.map do |map|
      FeedbackResponseMap.find_by(reviewed_object_id: map.id, reviewee_id: participant.id)
    end.compact

    feedback_scores_from_my_reviewees = get_reviews(feedback_from_my_reviewees_maps)

    avg_score_from_my_teammates = participant.aggregate_teammate_review_grade(reviews_of_me_maps)
    avg_score_to_my_teammates   = participant.aggregate_teammate_review_grade(reviews_by_me_maps)
    avg_score_from_my_authors   = participant.aggregate_teammate_review_grade(feedback_from_my_reviewees_maps)

    {
      participant_details:         participant,
      reviews_of_me:               reviews_of_me,
      reviews_by_me:               reviews_by_me,
      author_feedback_scores:      feedback_scores_from_my_reviewees,
      avg_score_from_my_teammates: avg_score_from_my_teammates,
      avg_score_to_my_teammates:   avg_score_to_my_teammates,
      avg_score_from_my_authors:   avg_score_from_my_authors
    }
  end

  # Returns heatgrid data for a collection of maps (ReviewResponseMap/FeedbackResponseMap/TeammateReviewResponseMap).
  # Groups submitted scores by round symbol (:Review-Round-1, etc.) and injects SectionHeader sentinels.
  def get_reviews(maps)
    reviewee_scores = {}
    return reviewee_scores if maps.empty?

    # Resolve the DB-stored questionnaire_type(s) once, hoisted above both branches.
    # maps.first.questionnaire_type returns a short form: 'Review', 'TeammateReview',
    # or 'AuthorFeedback'. The questionnaires table stores the full class name, but
    # 'AuthorFeedback' has two historical variants: 'Author FeedbackQuestionnaire' (with
    # space) and 'AuthorFeedbackQuestionnaire' (no space). Matching against
    # Questionnaire::QUESTIONNAIRE_TYPES with a whitespace-insensitive compare covers both
    # and generates an IN clause, so neither variant is silently missed.
    short_type = maps.first.questionnaire_type
    db_questionnaire_types = Questionnaire::QUESTIONNAIRE_TYPES.select { |t|
      t.gsub(' ', '').casecmp?("#{short_type}Questionnaire")
    }

    if @assignment.varying_rubrics_by_round?
      rounds = @assignment.review_rounds(short_type)
      rounds.each do |round|
        aq = AssignmentQuestionnaire
               .joins(:questionnaire)
               .where(assignment_id: @assignment.id, used_in_round: round)
               .where(questionnaires: { questionnaire_type: db_questionnaire_types })
               .first
        reviewee_scores = accumulate_round_scores(reviewee_scores, maps, round, aq&.questionnaire_id)
      end
    else
      # varying_rubrics_by_round? == false does NOT mean single-round — the same rubric
      # may be reused across multiple rounds. Discover actual rounds from submitted responses.
      rounds = maps.flat_map { |map|
        map.responses.select(&:is_submitted).map(&:round)
      }.compact.uniq.sort

      return reviewee_scores if rounds.empty?

      # For non-varying assignments, AssignmentQuestionnaire is stored with used_in_round: nil
      # regardless of how many actual response rounds exist. Look it up once outside the loop.
      aq = AssignmentQuestionnaire
             .joins(:questionnaire)
             .where(assignment_id: @assignment.id, used_in_round: nil)
             .where(questionnaires: { questionnaire_type: db_questionnaire_types })
             .first

      rounds.each do |round|
        reviewee_scores = accumulate_round_scores(reviewee_scores, maps, round, aq&.questionnaire_id)
      end
    end

    reviewee_scores
  end

  # Accumulates scores for one round into reviewee_scores and inserts section header marker objects.
  # Extracted from get_reviews to eliminate the ~50-line duplicate that existed
  # between the varying-rubric and non-varying branches.
  def accumulate_round_scores(reviewee_scores, maps, round, questionnaire_id)
    round_symbol = "#{maps.first.questionnaire_type}-Round-#{round}".to_sym
    reviewee_scores[round_symbol] = []

    maps.each_with_index do |map, index|
      submitted_response = map.responses.select { |r|
        r.round == round && r.is_submitted && r.map_id == map.id
      }.last
      next if submitted_response.nil?

      # Filter SectionHeader answers in Ruby — scores and items are already preloaded
      # via .includes(responses: { scores: :item }) on the maps query, so no extra DB hit.
      scored_answers = submitted_response.scores.reject { |s| s.item.question_type == 'SectionHeader' }

      scored_answers.each_with_index do |score, idx|
        reviewee_scores[round_symbol][idx] ||= []
        reviewee_scores[round_symbol][idx] << get_answer(score, index, submitted_response)
      end
    end

    reviewee_scores[round_symbol].each_with_index do |scores_array, idx|
      reviewee_scores[round_symbol][idx] = scores_array.sort_by { |answer|
        [answer[:reviewer_name].downcase, answer[:reviewee_name].downcase]
      }
    end

    insert_section_headers(reviewee_scores[round_symbol], questionnaire_id)
    reviewee_scores
  end

  # Splices { type: "header", txt: "..." } sentinel hashes into a round's scores array at
  # positions matching each SectionHeader item in the questionnaire's item sequence.
  # SectionHeaders have no answers so they never appear in the scores loop — this pass
  # re-inserts them so the frontend can render heading rows between score rows.
  def insert_section_headers(round_scores, questionnaire_id)
    return round_scores if questionnaire_id.nil?

    all_items = Item.where(questionnaire_id: questionnaire_id).order(:seq)
    scored_count = 0
    headers_to_insert = {}   # scored_position => header_txt

    all_items.each do |item|
      if item.question_type == 'SectionHeader'
        headers_to_insert[scored_count] = item.txt
      else
        scored_count += 1
      end
    end

    offset = 0
    headers_to_insert.sort.each do |position, header_txt|
      round_scores.insert(position + offset, { type: "header", txt: header_txt })
      offset += 1
    end

    round_scores
  end

  def get_answer(score, index, response = nil)
    response ||= score.response

    reviewer_name = if current_user_has_all_heatgrid_data_privileges?(@assignment)
                     response&.reviewer&.fullname
                   else
                     "Participant #{index + 1}"
                   end

    reviewee_name = response&.reviewee&.fullname

    {
      id:            score.id,
      item_id:       score.item_id,
      txt:           score.item.txt,
      answer:        score.answer,
      comments:      score.comments,
      reviewer_name: reviewer_name,
      reviewee_name: reviewee_name
    }
  end
end

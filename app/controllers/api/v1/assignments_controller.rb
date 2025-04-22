class Api::V1::AssignmentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # GET /api/v1/assignments
  def index
    assignments = Assignment.all
    render json: assignments
  end

  # GET /api/v1/assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    render json: assignment
  end

  # POST /api/v1/assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      render json: assignment, status: :created
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    if assignment.update(assignment_params)
      render json: assignment, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  def not_found
    render json: { error: "Assignment not found" }, status: :not_found
  end

  # DELETE /api/v1/assignments/:id
  def destroy
    assignment = Assignment.find_by(id: params[:id])
    if assignment
      if assignment.destroy
        render json: { message: "Assignment deleted successfully!" }, status: :ok
      else
        render json: { error: "Failed to delete assignment", details: assignment.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Assignment not found" }, status: :not_found
    end
  end
  
  #add participant to assignment
  def add_participant
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_participant = assignment.add_participant(params[:user_id])
      if new_participant.save
        render json: new_participant, status: :ok
      else
        render json: new_participant.errors, status: :unprocessable_entity
      end
    end
  end

  #remove participant from assignment
  def remove_participant
    user = User.find_by(id: params[:user_id])
    assignment = Assignment.find_by(id: params[:assignment_id])
    if user && assignment
      assignment.remove_participant(user.id)
      if assignment.save
        render json: { message: "Participant removed successfully!" }, status: :ok
      else
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = user ? "Assignment not found" : "User not found"
      render json: { error: not_found_message }, status: :not_found
    end
  end


  # make course_id of assignment null
  def remove_assignment_from_course
    assignment = Assignment.find(params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      assignment = assignment.remove_assignment_from_course
      if assignment.save
        render json: assignment , status: :ok
      else
        render json: assignment.errors, status: :unprocessable_entity
      end
    end
    
  end

  #update course id of an assignment/ assign the assign to some together course
  def assign_course
    assignment = Assignment.find(params[:assignment_id])
    course = Course.find(params[:course_id])
    if assignment && course
      assignment = assignment.assign_course(course.id)
      if assignment.save
        render json: assignment, status: :ok
      else
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = course ? "Assignment not found" : "Course not found"
      render json: { error: not_found_message }, status: :not_found
    end
  end

  #copy existing assignment
  def copy_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_assignment = assignment.copy
      if new_assignment.save
        render json: new_assignment, status: :ok
      else
        render json :new_assignment.errors, status: :unprocessable_entity
      end
    end
  end

  # Retrieves assignment details including `has_badge`, `pair_programming_enabled`,
  # `is_calibrated`, and `staggered_and_no_topic`.
  def show_assignment_details
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: {
        id: assignment.id,
        name: assignment.name,
        has_badge: assignment.has_badge?,
        pair_programming_enabled: assignment.pair_programming_enabled?,
        is_calibrated: assignment.is_calibrated?,
        staggered_and_no_topic: get_staggered_and_no_topic(assignment)
      }, status: :ok
    end
  end

  # check if assignment has topics
  # has_topics is set to true if there is SignUpTopic corresponding to the input assignment id 
  def has_topics
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.topics?, status: :ok
    end
  end

  # check if assignment is a team assignment 
  # true if assignment's max team size is greater than 1
  def team_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.team_assignment?, status: :ok
    end
  end

  def teams
    assignment = Assignment.find_by(id: params[:assignment_id])
  
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end
  
    submissions = if assignment.has_teams?
      assignment.teams.includes(:teams_users => :user).map do |team|
        signed_up_team = team.signed_up_teams.first
        topic = signed_up_team&.sign_up_topic&.topic_name
  
        {
          id: team.id,
          name: team.name,
          team_id: team.id,
          topic: topic,
          members: team.teams_users.map { |tu| { id: tu.user.id, name: tu.user.name } }
        }
      end
    else
      assignment.participants.includes(:user).map do |participant|
        {
          id: participant.id,
          name: participant.user.name,
          team_id: nil,
          topic: nil,
          members: [{ id: participant.user.id, name: participant.user.name }]
        }
      end
    end
  
    render json: submissions, status: :ok
  end 


  def reviews
    assignment = Assignment.find_by(id: params[:assignment_id])
    return render json: { error: "Assignment not found" }, status: :not_found if assignment.nil?
  
    current_team_id = params[:team_id]
    return render json: { error: "Team ID required" }, status: :bad_request if current_team_id.nil?
  
    is_team_based = assignment.has_teams?
    review_data = {
      author_feedback_reviews: [],
      teammate_reviews: []
    }
  
    review_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id)
  
    review_maps.each do |map|
      responses = Response.where(map_id: map.id).includes(scores: :item)  # Include Item (Question)
  
      responses.each do |response|
        reviewer_user = map.reviewer.try(:user)
        next if reviewer_user.nil?
  
        reviewee_team_id = map.reviewee_id
        is_teammate_review = reviewer_user.teams_users.pluck(:team_id).include?(current_team_id.to_i)
  
        response.scores.each do |answer|
          review_entry = {
            reviewer: {
              id: reviewer_user.id,
              name: reviewer_user.name
            },
            reviewee: begin
              if is_team_based
                team = Team.find_by(id: map.reviewee_id)
                { id: team&.id, name: team&.name }
              else
                user = Participant.find_by(id: map.reviewee_id)&.user
                { id: user&.id, name: user&.name }
              end
            end,
            question: answer.item&.txt,  # Add question text here
            comments: answer.comments,
            score: answer.answer,
            date: response.updated_at.to_date.to_s,
            team_based: is_team_based
          }
  
          if is_teammate_review
            review_data[:teammate_reviews] << review_entry
          else
            review_data[:author_feedback_reviews] << review_entry
          end
        end
      end
    end
  
    render json: review_data, status: :ok
  end
  

  # check if assignment has valid number of reviews
  # greater than required reviews for a valid review type
  def valid_num_review
    assignment = Assignment.find_by(id: params[:assignment_id])
    review_type = params[:review_type]
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.valid_num_review(review_type), status: :ok
    end
  end

  # check if assignment has teams
  # true if there exists a team corresponding to the input assignment id
  def has_teams
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.teams?, status: :ok
    end
  end

  # check if assignment has varying rubric across rounds
  # set to true if rubrics vary across rounds in assignment else false
  def varying_rubrics_by_round?
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      if AssignmentQuestionnaire.exists?(assignment_id: assignment.id)
        render json: assignment.varying_rubrics_by_round?, status: :ok
      else
        render json: { error: "No questionnaire/rubric exists for this assignment." }, status: :not_found
      end
    end
  end
  
  private
  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(:title, :description)
  end

  # Helper method to determine staggered_and_no_topic for the assignment
  def get_staggered_and_no_topic(assignment)
    topic_id = SignedUpTeam
               .joins(team: :teams_users)
               .where(teams_users: { user_id: current_user.id, team_id: Team.where(assignment_id: assignment.id).pluck(:id) })
               .pluck(:sign_up_topic_id)
               .first

    assignment.staggered_and_no_topic?(topic_id)
  end
end
class Api::V1::BookmarksController < ApplicationController
#   include AuthorizationHelper
#   include Scoring
  # helper_method :specific_average_score
  # helper_method :total_average_score
  before_action :set_bookmark, only: %i[ update ]

  def action_allowed?
    case params[:action]
    when 'list'
      current_role_name =~ /^(Student|Instructor|Teaching Assistant)$/
    when 'new', 'create', 'bookmark_rating', 'save_bookmark_rating_score'
      current_role_name.eql? 'Student'
    when 'edit', 'update', 'destroy'
      # edit, update, delete bookmarks can only be done by owner
      current_user_has_student_privileges? && current_user_created_bookmark_id?(params[:id])
    end
    @current_role_name = current_role_name
  end

  def list
    @bookmarks = Bookmark.where(topic_id: params[:id])
    # @topic = SignUpTopic.find(params[:id]) # signup topic not implemented yet
    render json: @bookmarks, status: :ok and return
  end

  def create
    begin
      create_bookmark_params[:url] = create_bookmark_params[:url].gsub!(%r{http://}, '') if create_bookmark_params[:url].present? && create_bookmark_params[:url].start_with?('http://')
      create_bookmark_params[:url] = create_bookmark_params[:url].gsub!(%r{https://}, '') if create_bookmark_params[:url].present? && create_bookmark_params[:url].start_with?('https://')
      @bookmark = Bookmark.new(create_bookmark_params)
      @bookmark.user_id = @current_user.id
      @bookmark.save!
      render json: @bookmark, status: :created and return
    rescue ActiveRecord::RecordInvalid
      render json: $ERROR_INFO.to_s, status: :unprocessable_entity
    end
  end

  def update
    update_bookmark_params[:url] = update_bookmark_params[:url].gsub!(%r{http://}, '') if update_bookmark_params[:url].start_with?('http://')
    update_bookmark_params[:url] = update_bookmark_params[:url].gsub!(%r{https://}, '') if update_bookmark_params[:url].start_with?('https://')
    if @bookmark.update(update_bookmark_params)
      render json: @bookmark, status: :ok
    else
      render json: @bookmark.errors.full_messages, status: :unprocessable_entity
    end
  end


  def destroy
    @bookmark = Bookmark.find(params[:id])
    @bookmark.destroy
    rescue ActiveRecord::RecordNotFound
        render json: $ERROR_INFO.to_s, status: :not_found
  end


  def bookmark_rating
    @bookmark = Bookmark.find(params[:id])
  end

  def save_bookmark_rating_score
    @bookmark = Bookmark.find(params[:id])
    @bookmark_rating = BookmarkRating.where(bookmark_id: @bookmark.id, user_id: @current_user.id).first
    if @bookmark_rating.blank?
      @bookmark_rating = BookmarkRating.create(bookmark_id: @bookmark.id, user_id: @current_user.id, rating: params[:rating])
    else
      @bookmark_rating.update({'rating': params[:rating].to_i})
    end
    render json: {"bookmark": @bookmark, "rating": @bookmark_rating}, status: :ok
  end

  # calculate average questionnaire score for 'Your rating' for specific bookmark
  def specific_average_score
    @bookmark = Bookmark.find(params[:id])
    if @bookmark.nil?
      render json: {"score": "-"}, status: :ok  
    else
      assessment = SignUpTopic.find(bookmark.topic_id).assignment
      questions = assessment.questionnaires.where(type: 'BookmarkRatingQuestionnaire').flat_map(&:questions)
      responses = BookmarkRatingResponseMap.where(
        reviewed_object_id: assessment.id,
        reviewee_id: bookmark.id,
        reviewer_id: AssignmentParticipant.find_by(user_id: current_user.id).id
      ).flat_map { |r| Response.where(map_id: r.id) }
      score = 10 # assessment_score(response: responses, questions: questions) # Scoring module not implemented
      if score.nil?
        render json: {"score": "-"}, status: :ok  
      else
        render json: {"score": (score * 5.0 / 100.0).round(2)}, status: :ok  
      end
    end
  end
  
  # calculate average questionnaire score for 'Avg. rating' for specific bookmark
  def total_average_score(bookmark)
    if bookmark.nil?
      render json: {"score": "-"}, status: :ok  
    else
      assessment = SignUpTopic.find(bookmark.topic_id).assignment
      questions = assessment.questionnaires.where(type: 'BookmarkRatingQuestionnaire').flat_map(&:questions)
      responses = BookmarkRatingResponseMap.where(
        reviewed_object_id: assessment.id,
        reviewee_id: bookmark.id
        ).flat_map { |r| Response.where(map_id: r.id) }
        totalScore = {"avg": 10} # aggregate_assessment_scores(responses, questions) # Scoring module not implemented
        if totalScore[:avg].nil?
          render json: {"score": "-"}, status: :ok  
        else
          render json: {"score": (totalScore[:avg] * 5.0 / 100.0).round(2)}, status: :ok  
        
      end
    end
  end

  private

  # TODO: Create a common definition for both create and update to reduce it to single params method
  # Change create method to take bookmark param as required.
  def create_bookmark_params
    params.require(:bookmark).permit(:url, :title, :description, :topic_id, :rating, :id)
  end

  def update_bookmark_params
    params.require(:bookmark).permit(:url, :title, :description)
  end

  def set_bookmark
    @bookmark = Bookmark.find(params[:id])
  end

  
end

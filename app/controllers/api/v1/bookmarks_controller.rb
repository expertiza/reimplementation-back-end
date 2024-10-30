class Api::V1::BookmarksController < ApplicationController
  include AuthorizationHelper
  # ensure that action_allowed? returns true before any action
  before_action :check_action_allowed

  # Index method returns the list of JSON objects of the bookmark
  # GET on /bookmarks
  def index
    @bookmarks = Bookmark.order(:id)
    render json: @bookmarks, status: :ok and return
  end

  # Show method returns the JSON object of bookmark with id = {:id}
  # GET on /bookmarks/:id
  def show
    begin
      @bookmark = Bookmark.find(params[:id])
      render json: @bookmark, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # Create method creates a bookmark and returns the JSON object of the created bookmark
  # POST on /bookmarks
  def create
    begin
      # params[:user_id] = @current_user.id
      @bookmark = Bookmark.new(bookmark_params)
      @bookmark.user_id = @current_user.id
      @bookmark.save!
      render json: @bookmark, status: :created and return
    rescue ActiveRecord::RecordInvalid
      render json: $ERROR_INFO.to_s, status: :unprocessable_entity
    end
  end

  # Update method updates the bookmark object with id - {:id} and returns the updated bookmark JSON object
  # PUT on /bookmarks/:id
  def update
    @bookmark = Bookmark.find(params[:id])
    if @bookmark.update(update_bookmark_params)
      render json: @bookmark, status: :ok
    else
      render json: @bookmark.errors.full_messages, status: :unprocessable_entity
    end
  end

  # Destroy method deletes the bookmark object with id- {:id}
  # DELETE on /bookmarks/:id
  def destroy
    begin
      @bookmark = Bookmark.find(params[:id])
      @bookmark.delete
    rescue ActiveRecord::RecordNotFound
        render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # get_bookmark_rating_score method gets the bookmark rating of the bookmark object with id- {:id}
  # GET on /bookmarks/:id/bookmarkratings
  def get_bookmark_rating_score
    begin
      @bookmark = Bookmark.find(params[:id])
      @bookmark_rating = BookmarkRating.where(bookmark_id: @bookmark.id, user_id: @current_user.id).first
      render json: @bookmark_rating, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # save_bookmark_rating_score method creates or updates the bookmark rating of the bookmark object with id- {:id}
  # POST on /bookmarks/:id/bookmarkratings
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

  private

  def bookmark_params
    params.require(:bookmark).permit(:url, :title, :description, :topic_id, :rating, :id)
  end

  def update_bookmark_params
    params.require(:bookmark).permit(:url, :title, :description)
  end


  # Check if the user is allowed to perform the action
  def action_allowed?
    user = @current_user
    case params[:action]
    when 'list', 'index', 'show', 'get_bookmark_rating_score'
      # Those with student privileges and above can view the list of bookmarks
      current_user_has_student_privileges?
    when 'new', 'create', 'bookmark_rating', 'save_bookmark_rating_score'
      # Those with strictly student privileges can create a new bookmark, rate a bookmark, or save a bookmark rating
      current_user_has_student_privileges? && !current_user_has_ta_privileges?
      # This should work in theory, and it is cleaner!
      # user.role.student?
    when 'edit', 'update', 'destroy'
      # Get the bookmark object
      bookmark = Bookmark.find(params[:id])
      case user.role.name
        when 'Student'
            # edit, update, delete bookmarks can only be done by owner
            current_user_created_bookmark_id?(params[:id])
        when 'Teaching Assistant'
            # edit, update, delete bookmarks can only be done by TA of the assignment
            current_user_has_ta_mapping_for_assignment?(bookmark.topic.assignment)
        when 'Instructor'
            # edit, update, delete bookmarks can only be done by instructor of the assignment
            current_user_instructs_assignment?(bookmark.topic.assignment)
        when 'Administrator'
            # edit, update, delete bookmarks can only be done by administrator who is the parent of the instructor of the assignment
            user == bookmark.topic.assignment.instructor.parent
        when 'Super Administrator'
            # edit, update, delete bookmarks can be done by super administrator
            true
        end
    end
  end

  def check_action_allowed
    unless action_allowed?
      render json: { error: 'Unauthorized access' }, status: :unauthorized
    end
  end

end
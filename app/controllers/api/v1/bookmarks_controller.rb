class Api::V1::BookmarksController < ApplicationController
  before_action :set_bookmark, only: %i[ update ]

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
    if @bookmark.update(bookmark_params)
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

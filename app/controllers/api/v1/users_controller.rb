class Api::V1::UsersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found

  def index
    @users = User.all
    render json: @users, status: :ok
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    render json: @user, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /users
  def create
    # Add default password for a user if the password is not provided
    params[:user][:password] ||= 'password'
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      render json: @user, status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    render json: { message: "User with id #{params[:id]}, deleted" }, status: :ok
  end

  # GET /api/v1/users/institution/:id
  # Get all users for an institution
  def institution_users
    @institution = Institution.find(params[:id])
    @users = @institution.users
    render json: @users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # GET /api/v1/users/:id/managed
  # Get all users that are managed by a user
  def managed_users
    @parent = User.find(params[:id])
    @users = @parent.manageable_users
    render json: @users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:id, :name, :role_id, :fullname, :email, :parent_id, :institution_id,
                                 :email_on_review, :email_on_submission, :email_on_review_of_review,
                                 :handle, :copy_of_emails, :password, :password_confirmation)
  end

  def user_not_found
    render json: { error: "User with id #{params[:id]} not found" }, status: :not_found
  end
end
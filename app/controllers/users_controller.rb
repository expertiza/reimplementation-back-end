# frozen_string_literal: true

class UsersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  before_action :set_user, only: %i[show update destroy managed_users]

  # GET /users
  def index
    render json: User.all, status: :ok
  end

  # GET /users/:id
  def show
    render json: @user, status: :ok
  end

  # POST /users
  def create
    params[:user][:password] ||= 'password'
    user = User.new(user_params)

    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    if @user.update(user_params)
      render json: @user, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    name = @user.name
    @user.destroy
    render json: { message: "User #{name} with id #{params[:id]} deleted successfully!" }, status: :no_content
  end

  # GET /users/institution/:id
  def institution_users
    institution = Institution.find(params[:id])
    render json: institution.users, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Institution with id #{params[:id]} not found" }, status: :not_found
  end

  # GET /users/:id/managed
  def managed_users
    if @user.student?
      render json: { error: 'Students do not manage any users' }, status: :unprocessable_entity
      return
    end

    render json: @user.managed_users, status: :ok
  end

  # GET /users/role/:name
  def role_users
    role_name = params[:name].split('_').map(&:capitalize).join(' ')
    role = Role.find_by!(name: role_name)
    render json: role.users, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Role '#{role_name}' not found" }, status: :not_found
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :id, :name, :role_id, :full_name, :email, :parent_id, :institution_id,
      :email_on_review, :email_on_submission, :email_on_review_of_review,
      :handle, :copy_of_emails, :password, :password_confirmation
    )
  end

  def user_not_found
    render json: { error: "User with id #{params[:id]} not found" }, status: :not_found
  end

  def parameter_missing
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end
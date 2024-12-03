class Api::V1::UsersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def index
    users = User.all
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched all users.", request)
    render json: users, status: :ok
  end

  # GET /users/:id
  def show
    user = User.find(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched user with ID: #{user.id}.", request)
    render json: user, status: :ok
  end

  # POST /users
  def create
    # Add default password for a user if the password is not provided
    params[:user][:password] ||= 'password'
    user = User.new(user_params)
    if user.save
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Created user with ID: #{user.id}.", request)
      render json: user, status: :created
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to create user. Errors: #{user.errors.full_messages.join(', ')}", request)
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    user = User.find(params[:id])
    if user.update(user_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Updated user with ID: #{user.id}.", request)
      render json: user, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Failed to update user with ID: #{user.id}. Errors: #{user.errors.full_messages.join(', ')}", request)
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    user = User.find(params[:id])
    user.destroy
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Deleted user with ID: #{user.id}.", request)
    render json: { message: "User #{user.name} with id #{params[:id]} deleted successfully!" }, status: :no_content
  end

  # GET /api/v1/users/institution/:id
  # Get all users for an institution
  def institution_users
    institution = Institution.find(params[:id])
    users = institution.users
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched users for institution ID: #{institution.id}.", request)
    render json: users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Institution not found with ID: #{params[:id]}. Error: #{e.message}", request)
    render json: { error: e.message }, status: :not_found
  end

  # GET /api/v1/users/:id/managed
  # Get all users that are managed by a user
  def managed_users
    parent = User.find(params[:id])
    if parent.student?
      ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "User ID: #{parent.id} is a student and cannot manage users.", request)
      render json: { error: 'Students do not manage any users' }, status: :unprocessable_entity
      return
    end
    parent = User.instantiate(parent)
    users = parent.managed_users
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched managed users for user ID: #{parent.id}.", request)
    render json: users, status: :ok
  end

  # Get role based users
  # GET /api/v1/users/role/:name
  def role_users
    name = params[:name].split('_').map(&:capitalize).join(' ')
    role = Role.find_by(name:)
    users = role.users
    ExpertizaLogger.info LoggerMessage.new(controller_name, @current_user.name, "Fetched users for role: #{name}.", request)
    render json: users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Role not found with name: #{name}. Error: #{e.message}", request)
    render json: { error: e.message }, status: :not_found
  end

  private

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:id, :name, :role_id, :full_name, :email, :parent_id, :institution_id,
                                 :email_on_review, :email_on_submission, :email_on_review_of_review,
                                 :handle, :copy_of_emails, :password, :password_confirmation)
  end

  def user_not_found
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "User not found with ID: #{params[:id]}.", request)
    render json: { error: "User with id #{params[:id]} not found" }, status: :not_found
  end

  def parameter_missing
    ExpertizaLogger.error LoggerMessage.new(controller_name, @current_user.name, "Parameter missing.", request)
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

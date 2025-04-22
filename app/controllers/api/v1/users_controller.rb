class Api::V1::UsersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def index
    users = User.all
    render json: users, status: :ok
  end

  # GET /users/:id
  def show
    user = User.find(params[:id])
    render json: user, status: :ok
  end

  # POST /users
  def create
    # Add default password for a user if the password is not provided
    params[:user][:password] ||= 'password'
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: user, status: :ok
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    user = User.find(params[:id])
    user.destroy
    render json: { message: "User #{user.name} with id #{params[:id]} deleted successfully!" }, status: :no_content
  end

  # GET /api/v1/users/institution/:id
  # Get all users for an institution
  def institution_users
    institution = Institution.find(params[:id])
    users = institution.users
    render json: users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # GET /api/v1/users/:id/managed
  # Get all users that are managed by a user
  def managed_users
    parent = User.find(params[:id])
    if parent.student?
      render json: { error: 'Students do not manage any users' }, status: :unprocessable_entity
      return
    end
    parent = User.instantiate(parent)
    users = parent.managed_users
    render json: users, status: :ok
  end

  # Get role based users
  # GET /api/v1/users/role/:name
  def role_users
    name = params[:name].split('_').map(&:capitalize).join(' ')
    role = Role.find_by(name:)
    users = role.users
    render json: users, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end
  
  # GET /api/v1/users/:id/profile : Returns basic user profile information and email preferences
  def profile
    user = User.find(params[:id])
    render json: user.slice(:id, :name, :email, :full_name,
                            :email_on_review, :email_on_submission, :email_on_review_of_review),
           status: :ok
  end

  # PUT /api/v1/users/:id/profile : Allows updating profile details like full_name, email, and email preferences
  def update_profile
    user = User.find(params[:id])
    if user.update(user_profile_params)
      render json: { message: 'Profile updated successfully' }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/users/:id/password : Allows changing the user's password securely. 
  def change_password
    user = User.find(params[:id])
  
    # Ensure both current and new passwords are provided
    unless params[:current_password].present? && params[:new_password].present?
      return render json: { error: 'Both current_password and new_password are required' }, status: :bad_request
    end
  
    if user.authenticate(params[:current_password])
      if user.update(password: params[:new_password])
        
        render json: { message: 'Password changed successfully' }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:id, :name, :role_id, :full_name, :email, :parent_id, :institution_id,
                                 :email_on_review, :email_on_submission, :email_on_review_of_review,
                                 :handle, :copy_of_emails, :password, :password_confirmation)
  end

  # Allowed params for profile update only
  def user_profile_params
    params.require(:user).permit(:email, :full_name, :email_on_review,
                                 :email_on_submission, :email_on_review_of_review)
  end
  
  def user_not_found
    render json: { error: "User with id #{params[:id]} not found" }, status: :not_found
  end

  def parameter_missing
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

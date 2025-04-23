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
    render json: user.as_json(except: [:password_digest]), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
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

  # GET /api/v1/users/:id/get_profile : Returns basic user profile information and email preferences
  def get_profile
    user = User.includes(:institution).find(params[:id])

    render json: {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      handle: user.handle || '',
      can_show_actions: user.can_show_actions,
      time_zone: user.time_zone || 'GMT-05:00',
      language: user.language || 'No Preference',
      email_on_review: user.email_on_review.nil? ? true : user.email_on_review,
      email_on_submission: user.email_on_submission.nil? ? true : user.email_on_submission,
      email_on_review_of_review: user.email_on_review_of_review.nil? ? true : user.email_on_review_of_review,
      institution: {
        id: user.institution&.id || 0,
        name: user.institution&.name || 'Other'
      }
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # PATCH /users/:id
  def update_profile
    user = User.find(params[:id])
  
    if user.update(user_params)
      render json: {
        message: 'Profile updated successfully.',
        user: user.as_json(except: [:password_digest])
      }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # POST /users/:id/update_password
  # def update_password
  #   user = User.find(params[:id])
  
  #   unless user.authenticate(params[:current_password])
  #     return render json: { error: 'Current password is incorrect' }, status: :unauthorized
  #   end
  
  #   if user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
  #     # TODO: Invalidate sessions or issue new token here
  #     render json: { message: 'Password updated successfully' }, status: :ok
  #   else
  #     render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
  #   end
  # end

  def update_password
    user = User.find(params[:id])
  
    password = params[:password]
    confirm_password = params[:confirmPassword]

    if password.blank? || confirm_password.blank?
      return render json: { error: 'Both password and confirmPassword are required' }, status: :bad_request
    end
  
    if password != confirm_password
      return render json: { error: 'Passwords do not match' }, status: :unprocessable_entity
    end

    if user.update(password: password, password_confirmation: confirm_password)
      # update jwt_version and issue new token
      user.update(jwt_version: SecureRandom.uuid)
  
      payload = {
        id: user.id,
        name: user.name,
        full_name: user.full_name,
        role: user.role.name,
        institution_id: user.institution.id,
        jwt_version: user.jwt_version
      }

      new_token = JsonWebToken.encode(payload, 24.hours.from_now)

      render json: { 
        message: 'Password updated successfully',
        token: new_token,
        user: user.as_json(except: [:password_digest])
        }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  

  private

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:id, :name, :role_id, :full_name, :email, :parent_id, :institution_id,
                                 :email_on_review, :email_on_submission, :email_on_review_of_review,
                                 :handle, :copy_of_emails, :password, :password_confirmation, 
                                 :time_zone, :language, :can_show_actions)
  end

  # Allowed params for profile update only
  def user_profile_params
    params.require(:user).permit(:email, :full_name, :email_on_review,
                                 :email_on_submission, :email_on_review_of_review,
                                 :time_zone, :language, :can_show_actions)
  end
  
  def user_not_found
    render json: { error: "User with id #{params[:id]} not found" }, status: :not_found
  end

  def parameter_missing
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

class Api::V1::AccountRequestsController < ApplicationController

  before_action :is_admin?, only: %i[show index update destroy]

  # GET /account_requests
  def index
    # If history is true, return previously accepted or rejected account requests
    if params['history'] == 'true'
      @account_requests = AccountRequest.where.not(status: 'Under Review').order('updated_at DESC')
    # Else return pending account requests
    else
      @account_requests = AccountRequest.where(status: 'Under Review').order('created_at DESC')
    end
    render json: @account_requests, status: :ok
  end

  # POST /account_requests
  def create
    @account_request = AccountRequest.new(account_request_params)
    if @account_request.save
      render json: @account_request, status: :created
    else
      render json: @account_request.errors, status: :unprocessable_entity
    end
  end

  # GET /account_requests/:id
  def show
    @account_request = AccountRequest.find(params[:id])
    render json: @account_request, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

   # PATCH/PUT /account_requests/:id
   def update
    @account_request = AccountRequest.find(params[:id])
    if @account_request.update(account_request_params)
      if @account_request.status == 'Approved'
        create_approved_user
      else
        render json: @account_request, status: :ok
      end
    else
      render json: @account_request.errors, status: :unprocessable_entity
    end
  end

  # DELETE /account_requests/:id
  def destroy
    @account_request = AccountRequest.find(params[:id])
    @account_request.destroy
    render json: { message: 'Account Request deleted' }, status: :ok
  end

  private

  # Is current user an Administrator?
  def is_admin?
    # Get current user's id from session variable for normal users and from env vars for Rspec tests
    user_id = Rails.env.test? ? ENV['TEST_USER_ID'] : session[:user_id]
    @current_user = User.find_by(id: user_id)
    unless @current_user && @current_user.role.name == 'Administrator'
      render json: { error: 'You are not authorized to perform this action. Please login as an Administrator using /users api below.' }, status: :unauthorized
    end
  end

  # Only allow a list of trusted parameters through.
  def account_request_params
    params[:account_request][:status] = 'Under Review' if params[:account_request][:status].nil?
    params.require(:account_request).permit(:name, :fullname, :email, :status, :self_introduction, :role_id, :institution_id)
  end

  # Create a new user if account request is approved
  def create_approved_user
    @new_user = User.new
    @new_user.name = @account_request.name
    @new_user.role_id = @account_request.role_id
    @new_user.institution_id = @account_request.institution_id
    @new_user.fullname = @account_request.fullname
    @new_user.email = @account_request.email
    @new_user.password = 'password'
    @new_user.parent_id = @current_user.id
    @new_user.timezonepref = @current_user.timezonepref
    if @new_user.save
      render json: { msg: 'Account Request Approved and User successfully created.', user: @new_user}, status: :ok
    else
      render json: @new_user.errors, status: :unprocessable_entity
    end
  end
end

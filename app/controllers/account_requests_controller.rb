class AccountRequestsController < ApplicationController

  # GET /account_requests/pending
  def pending_requests
    @account_requests = AccountRequest.where(status: 'Under Review').order('created_at DESC')
    render json: @account_requests, status: :ok
  end

  # GET /account_requests/processed
  def processed_requests
    @account_requests = AccountRequest.where.not(status: 'Under Review').order('updated_at DESC')
    render json: @account_requests, status: :ok
  end

  # POST /account_requests
  def create
    @account_request = AccountRequest.new(account_request_params)
    if @account_request.save
      response = { account_request: @account_request }
      if User.find_by(email: @account_request.email)
        response[:warnings] = 'WARNING: User with this email already exists!'
      end
      render json: response, status: :created
    else
      render json: @account_request.errors, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :parameter_missing
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /account_requests/:id
  def show
    @account_request = AccountRequest.find(params[:id])
    render json: @account_request, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # PATCH/PUT /account_requests/:id
  # This API is used to Approve or Reject an account request. If Approved, a new user is created.
  def update
    @account_request = AccountRequest.find(params[:id])
    @account_request.update(account_request_params)
    if @account_request.status == 'Approved'
      create_approved_user
    else
      render json: @account_request, status: :ok
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /account_requests/:id
  def destroy
    @account_request = AccountRequest.find(params[:id])
    @account_request.destroy
    render json: { message: 'Account Request deleted' }, status: :no_content
  rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
  end

  private

  # Only allow a list of trusted parameters through.
  def account_request_params
    # For new account request creation, status sent is null. So, status is set to 'Under Review' by default
    if params[:account_request][:status].nil?
      params[:account_request][:status] = 'Under Review'
    # For Approval or Rejection of an existing request, raise error if user sends a status other than Approved or Rejected
    elsif !['Approved', 'Rejected'].include?(params[:account_request][:status])
      raise StandardError, 'Status can only be Approved or Rejected'
    end
    params.require(:account_request).permit(:username, :full_name, :email, :status, :introduction, :role_id, :institution_id, :date_format_pref)
  end

  # Create a new user if account request is approved
  def create_approved_user
    if User.exists?(email: @account_request.email)
      render json: { error: 'A user with this email already exists. Cannot approve the account request.' }, status: :unprocessable_entity
      return
    end
    @new_user = User.new(name: @account_request.username, role_id: @account_request.role_id, institution_id: @account_request.institution_id, full_name: @account_request.full_name, email: @account_request.email, password: 'password')
    if @new_user.save
      render json: { success: 'Account Request Approved and User successfully created.', user: @new_user}, status: :ok
    else
      render json: @new_user.errors, status: :unprocessable_entity
    end
  end
end

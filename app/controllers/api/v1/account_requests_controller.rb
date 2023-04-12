class Api::V1::AccountRequestsController < ApplicationController

  before_action :is_admin?, only: %i[show index update destroy]

  # GET /account_requests
  def index
    if params['history'] == 'true'
      @account_requests = AccountRequest.where.not(status: 'Under Review').order('updated_at DESC')
    else
      @account_requests = AccountRequest.where(status: 'Under Review').order('created_at DESC')
    end
    @account_requests = @account_requests.paginate(page: params[:page], per_page: 10) unless @account_requests.empty?
    render json: @account_requests, status: :ok
  end

  private

  def is_admin?
    user_id = Rails.env.test? ? ENV['TEST_USER_ID'] : session[:user_id]
    current_user = User.find_by(id: user_id)
    unless current_user.role.name == 'Administrator'
      render json: { error: 'You are not authorized to perform this action' }, status: :unauthorized
    end
  end
end

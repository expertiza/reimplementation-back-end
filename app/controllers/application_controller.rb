# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_request!

  private

  def authenticate_request!
    @current_user = authorize_request
    render json: { error: 'Not Authorized' }, status: 401 unless @current_user
  end

  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    decoded = JsonWebToken.decode(token)
    User.find(decoded[:id]) if decoded
  rescue
    nil
  end

  def current_user
    @current_user
  end
end

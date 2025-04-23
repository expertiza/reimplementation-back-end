require 'json_web_token'
module JwtToken
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    attr_reader :current_user
  end

  private

  def authenticate_request!
    unless user_id_in_token?
      render json: { error: 'Not Authorized' }, status: :unauthorized
      return
    end
    @current_user = User.find(auth_token[:id])

    # # Invalidate token if jwt_version no longer matches
    # if auth_token[:jwt_version] != @current_user.jwt_version
    #   render json: { error: 'Token has been invalidated. Please login again.' }, status: :unauthorized
    #   return
    # end


  rescue JWT::VerificationError, JWT::DecodeError
    render json: { error: 'Not Authorized' }, status: :unauthorized
  end

  def http_token
    @http_token ||= if request.headers['Authorization'].present?
                      request.headers['Authorization'].split('Bearer ').last
                    end
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(http_token)
  end

  def user_id_in_token?
    http_token && auth_token && auth_token[:id].to_i
  end
end

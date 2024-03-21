class ApplicationController < ActionController::API
  include JwtToken
  # @current_user = User.find_by_name('admin')
end

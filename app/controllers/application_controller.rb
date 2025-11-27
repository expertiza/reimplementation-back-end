# frozen_string_literal: true

# Ensure concerns are loaded before including
require_relative 'concerns/authorization'
require_relative 'concerns/jwt_token'

class ApplicationController < ActionController::API
  include Authorization
  include JwtToken
  
  before_action :authorize

end

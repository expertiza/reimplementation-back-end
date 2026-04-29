# frozen_string_literal: true

# Ensure concerns are loaded before including
require_relative 'concerns/authorization'
require_relative 'concerns/jwt_token'
require_relative '../helpers/submitted_content_helper'
require_relative '../helpers/file_helper'

class ApplicationController < ActionController::API
  include Authorization
  include JwtToken
  
  before_action :authorize

end

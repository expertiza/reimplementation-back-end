# frozen_string_literal: true

# Ensure concerns are loaded before including
require_relative 'concerns/authorization'
require_relative 'concerns/jwt_token'
require_relative '../helpers/submitted_content_helper'
require_relative '../helpers/file_helper'

class ApplicationController < ActionController::API
  include Authorization
  include JwtToken
  prepend_before_action :set_response, only: %i[show update]
  before_action :find_and_authorize_map_for_create, only: %i[create]  # changed from prepend_before_action

  before_action :authorize

end

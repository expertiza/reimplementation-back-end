# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authorization
  include JwtToken
  
  before_action :authorize

end

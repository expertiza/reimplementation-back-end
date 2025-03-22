class ApplicationController < ActionController::API
  include Authorization
  include JwtToken
  
  before_action :authorize
  before_action :set_locale

  private

  def set_locale
    I18n.locale = current_user&.locale || I18n.default_locale
  end

end

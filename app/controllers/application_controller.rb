class ApplicationController < ActionController::API
  include Authorization
  include JwtToken

  # 1) Set locale for every request
  before_action :set_locale
  # 2) Perform authorization
  before_action :authorize

  private

  # Sets I18n.locale based on params, Accept-Language header, or default
  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  # Returns a valid locale symbol or nil
  def extract_locale
    # 1) Param override
    if params[:locale].present?
      sym = params[:locale].to_sym
      return sym if I18n.available_locales.include?(sym)
    end

    # 2) Accept-Language header fallback
    header = request.env['HTTP_ACCEPT_LANGUAGE'].to_s
    header
      .split(',')
      .map { |l| l[0..1].downcase.to_sym }
      .find { |loc| I18n.available_locales.include?(loc) }
  end
end

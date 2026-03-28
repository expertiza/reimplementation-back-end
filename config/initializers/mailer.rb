# frozen_string_literal: true

if ENV['MAILER_SERVER'].present? && ENV['MAILER_USER'].present?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.perform_deliveries = true
  Rails.application.config.action_mailer.smtp_settings = {
    address: ENV['MAILER_SERVER'],
    port: ENV['MAILER_SERVER_PORT']&.to_i || 587,
    domain: ENV['MAILER_DOMAIN'] || 'localhost',
    user_name: ENV['MAILER_USER'],
    password: ENV['MAILER_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true
  }
end

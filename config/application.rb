# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('8.0.0')
  class ActionMailer::Base
    def self.preview_path=(_)
      # no-op: This method is intentionally left blank for compatibility with Rails 8.
    end
  end
end
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module Reimplementation
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.active_record.schema_format = :ruby

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.cache_store = :redis_store, ENV['CACHE_STORE'], { expires_in: 3.days, raise_errors: false }

    # ── Action Mailer SMTP configuration ──
    # All values are pulled from environment variables so the block is safe
    # to load even when mailer env vars are absent (e.g. in dev/test).
    # Delivery will simply fail at send-time if credentials are missing,
    # rather than blowing up on boot.
    config.action_mailer.smtp_settings = {
      address: ENV['MAILER_SERVER'].presence || 'localhost',
      port: (ENV['MAILER_SERVER_PORT'].presence || '587').to_i,
      domain: ENV['MAILER_DOMAIN'].presence || 'localhost',

      # Only include credentials when they're actually provided.
      user_name: ENV['MAILER_USER'].presence,
      password: ENV['MAILER_PASSWORD'].presence,

      # :plain sends base64-encoded credentials — fine over TLS,
      # but skip authentication entirely when no user is configured.
      authentication: ENV['MAILER_USER'].present? ? :plain : nil,

      enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(
        ENV['MAILER_ENABLE_STARTTLS'].presence || 'true'
      )
    }
  end
end

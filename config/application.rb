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

    # Internationalization (i18n) Settings
    config.i18n.default_locale = :en_US  
    config.i18n.available_locales = [:en_US, :hi_IN]  
    config.i18n.fallbacks = [:en_US]  
  end
end

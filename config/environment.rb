# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# ── Frontend URL Configuration ──
raise "FRONTEND_DOMAIN must be configured via environment variables or config/environments/*.rb files" if Rails.configuration.x.frontend_domain.blank?

# This runs after all environment files are loaded, so environment-specific defaults are available
# URI::Generic.build expects nil for no port, but ENV vars are strings, so convert to int and back to handle blank/zero cases
uri = URI::Generic.build(
  scheme: Rails.configuration.x.frontend_scheme,
  host:   Rails.configuration.x.frontend_domain,
  port:   Rails.configuration.x.frontend_port.to_i.nonzero?
)
FRONTEND_URL = uri.to_s
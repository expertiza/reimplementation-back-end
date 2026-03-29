# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# ── Frontend URL Configuration ──
# This runs after all environment files are loaded, so environment-specific defaults are available
frontend_scheme = ENV.fetch('FRONTEND_SCHEME', 'http://')
frontend_domain = ENV.fetch('FRONTEND_DOMAIN', nil)
frontend_port = ENV.fetch('FRONTEND_PORT', nil)

raise "FRONTEND_DOMAIN must be configured via environment variables" if frontend_domain.blank?

# Build the frontend URL, omitting standard ports (80 for http, 443 for https)
is_standard_port = (frontend_scheme == 'http://' && frontend_port.to_i == 80) ||
                   (frontend_scheme == 'https://' && frontend_port.to_i == 443)
port_string = !frontend_port.blank? && !is_standard_port ? ":#{frontend_port}" : ''

unless Object.const_defined?(:FRONTEND_URL)
  FRONTEND_URL = "#{frontend_scheme}#{frontend_domain}#{port_string}"
end

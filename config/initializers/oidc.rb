Rails.application.config.after_initialize do
  OidcConfig.providers
rescue Errno::ENOENT
  Rails.logger.info("OIDC config file not found; OIDC disabled")
end
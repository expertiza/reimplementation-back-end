Rails.application.config.after_initialize do
  OidcConfig.providers
end
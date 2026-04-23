class OidcConfig
  class ProviderNotFound < StandardError; end
  class InvalidConfiguration < StandardError; end

  CONFIG_FILE = Rails.root.join("config", "oidc_providers.yml").freeze
  REQUIRED_KEYS = %w[display_name issuer client_id client_secret redirect_uri].freeze

  # Loads, parses, and validates the OIDC provider YAML file.
  # Memoized per process — call reload! to force a re-read.
  # In production, invalid config raises InvalidConfiguration to block startup.
  # In other environments, invalid providers are skipped with a warning.
  def self.providers
    @providers ||= begin
                     yaml = ERB.new(File.read(CONFIG_FILE)).result
                     parsed = YAML.safe_load(yaml, permitted_classes: [], aliases: true)

                     unless parsed.is_a?(Hash)
                       handle_invalid("OIDC config: expected top-level mapping in #{CONFIG_FILE}, got #{parsed.class}")
                       parsed = {}
                     end

                     providers = parsed["providers"]
                     unless providers.is_a?(Hash)
                       handle_invalid("OIDC config: expected 'providers' to be a mapping in #{CONFIG_FILE}, got #{providers.class}")
                       providers = {}
                     end

                     validate!(providers)
                   end
  end

  # Looks up a provider config by its key (e.g. "google-ncsu").
  # Raises ProviderNotFound if the key is not configured.
  def self.find(provider_key)
    providers.fetch(provider_key) do
      raise ProviderNotFound, "Unknown OIDC provider: #{provider_key}"
    end
  end

  # Returns the list of providers safe to expose to the frontend.
  # Only includes display information — never secrets or endpoint URLs.
  def self.public_list
    providers.map { |key, cfg| { id: key, name: cfg["display_name"] } }
  end

  # Clears the memoized config so the next call to `providers` re-reads the YAML file.
  # Primarily useful for tests and hot-reloading in development.
  def self.reload!
    @providers = nil
  end

  # Parses the provider's scopes string (whitespace or comma-separated) into an array.
  # Falls back to the default OIDC scopes if none are configured.
  def self.scopes_for(provider)
    raw = provider["scopes"].to_s.split(/[\s,]+/).reject(&:blank?)
    raw.presence || %w[openid email profile]
  end

  # Removes providers missing any REQUIRED_KEYS.
  # In production, raises InvalidConfiguration to prevent startup with misconfigured providers.
  # In other environments, logs a warning and skips the provider.
  def self.validate!(providers)
    providers.reject! do |key, cfg|
      missing = REQUIRED_KEYS.select { |k| cfg[k].blank? }
      if missing.any?
        handle_invalid("OIDC provider '#{key}' invalid: missing #{missing.join(', ')}")
        true
      end
    end
    providers
  end

  # Raises in production to block startup; logs a warning elsewhere.
  def self.handle_invalid(message)
    raise InvalidConfiguration, message if Rails.env.production?
    Rails.logger.warn(message)
  end

  private_class_method :validate!, :handle_invalid
end